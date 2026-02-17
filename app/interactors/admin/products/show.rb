module Admin
  module Products
    class Show
      attr_reader :product, :error

      def self.call(id:)
        new(id: id).call
      end

      def initialize(id:)
        @id = id
        @product = nil
        @error = nil
      end

      def call
        @product = Product.includes(:category, :product_prices).find_by(id: @id)
        unless @product
          @error = "Product not found"
        end
        self
      rescue StandardError => e
        @error = "Error loading product: #{e.message}"
        self
      end

      def success?
        @error.nil?
      end
    end
  end
end

