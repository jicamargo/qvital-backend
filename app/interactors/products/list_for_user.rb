module Products
  class ListForUser
    # No se puede usar un `.joins(:category)` normal para el ORDER BY: cuando `search_by_text`
    # (pg_search, ver Searchable) trae `category` en `associated_against`, pg_search agrega su
    # propio join aliased a la tabla `categories` y choca con uno explícito. Un subquery
    # correlacionado evita el conflicto de alias sin depender del join de ninguno de los dos.
    # Se proyecta como columna `category_position` en el SELECT (no solo en el ORDER BY) porque
    # Postgres exige, bajo `.distinct`, que toda expresión de ORDER BY aparezca en el select list.
    CATEGORY_POSITION_SELECT =
      "(SELECT position FROM categories WHERE categories.id = products.category_id) AS category_position"
    CATEGORY_POSITION_ORDER = "category_position ASC, products.name ASC"

    attr_reader :products, :error

    def self.call(user:, health_goal_key: nil, q: nil)
      new(user: user, health_goal_key: health_goal_key, q: q).call
    end

    def initialize(user:, health_goal_key: nil, q: nil)
      @user = user
      @health_goal_key = health_goal_key
      @q = q
      @products = []
      @error = nil
    end

    def call
      return failure('User is required') unless @user
      return failure('User level is required to calculate prices') unless @user.level_id

      load_products_for_level
      self
    rescue StandardError => e
      @error = "Unexpected error loading products: #{e.message}"
      Rails.logger.error @error
      self
    end

    def success?
      @error.nil?
    end

    private

    def load_products_for_level
      level_id = @user.level_id

      scope =
        Product
          .active
          .joins(:product_prices)
          .where(product_prices: { level_id: level_id })
          .preload(:category, :product_prices, :health_goals)
          .select("products.*", Arel.sql(CATEGORY_POSITION_SELECT))
          .distinct

      scope = scope.by_health_goal_key(@health_goal_key) if @health_goal_key.present?
      # `search_by_text` (pg_search) agrega su propio ORDER BY rank — `.reorder` en vez de
      # `.order` para que el catálogo siga ordenado por categoría/nombre y no arrastre esa
      # columna de rank (que además rompe el `.distinct` de arriba al no estar en el select).
      scope = scope.search_by_text(@q) if @q.present?
      scope = scope.reorder(Arel.sql(CATEGORY_POSITION_ORDER))

      @products = scope
    rescue StandardError => e
      failure("Error querying products: #{e.message}")
    end

    def failure(message)
      @error = message
      self
    end
  end
end

