module Recipes
  class ListForUser
    FALLBACK_LIMIT = 6

    attr_reader :recipes, :error

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
      @recipes = Recipe.none
      @error = nil
    end

    def call
      product_ids = purchased_product_ids

      @recipes = product_ids.empty? ? fallback_recipes : recipes_matching(product_ids)
      self
    rescue StandardError => e
      @error = "Error listing recipes for user: #{e.message}"
      self
    end

    def success?
      @error.nil?
    end

    private

    # Productos de compras confirmadas del usuario (ver PurchaseItem/Purchase).
    def purchased_product_ids
      PurchaseItem
        .joins(:purchase)
        .where(purchases: { user_id: @user.id, status: :confirmed })
        .distinct
        .pluck(:product_id)
    end

    # Sin compras aún: recetas destacadas/genéricas, mismo criterio que el
    # catálogo público, sin fallar (ver sub-fase 3.5).
    def fallback_recipes
      Recipe.active.includes(:health_goals, recipe_ingredients: :product).order(:title).limit(FALLBACK_LIMIT)
    end

    # Recetas cuyos ingredientes coinciden con productos ya comprados,
    # ordenadas por cantidad de coincidencias (más primero). Se calcula el
    # orden con una query aparte (en vez de combinar GROUP BY con los
    # `includes` de abajo) para no acoplar el conteo con el eager loading.
    def recipes_matching(product_ids)
      ordered_ids = RecipeIngredient
        .joins(:recipe)
        .where(product_id: product_ids, recipes: { active: true })
        .group(:recipe_id)
        .order(Arel.sql("COUNT(*) DESC"))
        .pluck(:recipe_id)

      recipes_by_id = Recipe.includes(:health_goals, recipe_ingredients: :product)
        .where(id: ordered_ids)
        .index_by(&:id)

      ordered_ids.map { |id| recipes_by_id[id] }.compact
    end
  end
end
