module Admin
  module Products
    class List
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
        scope = Product.includes(:category)
        scope = scope.where(active: to_bool(@params[:active])) if @params.key?(:active)
        scope = scope.where(category_id: @params[:category_id]) if @params[:category_id].present?

        if @params[:search].present?
          term = "%#{@params[:search].to_s.strip}%"
          scope = scope.where("products.name ILIKE :term OR products.sku ILIKE :term", term: term)
        end

        @products = scope.order(created_at: :desc)
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

