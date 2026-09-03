module Admin
  module Products
    class List
      # Ver la nota en Products::ListForUser::CATEGORY_POSITION_ORDER — mismo conflicto de alias
      # entre un `.joins(:category)` manual y el join que agrega `search_by_text` (pg_search).
      CATEGORY_POSITION_ORDER =
        "(SELECT position FROM categories WHERE categories.id = products.category_id) ASC, products.name ASC"

      attr_reader :products, :error

      def self.call(params: {})
        new(params: params).call
      end

      def initialize(params: {})
        @params = params || {}
        @products = Product.all
        @error = nil
      end

      def call
        scope = Product.preload(:category, :product_prices)
        scope = scope.where(active: to_bool(@params[:active])) if @params.key?(:active)
        scope = scope.where(category_id: @params[:category_id]) if @params[:category_id].present?

        scope = scope.search_by_text(@params[:search]) if @params[:search].present?

        # `.reorder` (no `.order`): `search_by_text` (pg_search) agrega su propio ORDER BY rank,
        # y el listado admin debe seguir ordenado por categoría/nombre igual que sin búsqueda.
        @products = scope.reorder(Arel.sql(CATEGORY_POSITION_ORDER))
        self
      rescue StandardError => e
        @error = "Error listing products: #{e.message}"
        self
      end

      def success?
        @error.nil?
      end

      private

      def to_bool(value)
        return true if value == true || value.to_s.downcase == "true"
        return false if value == false || value.to_s.downcase == "false"
        nil
      end
    end
  end
end

