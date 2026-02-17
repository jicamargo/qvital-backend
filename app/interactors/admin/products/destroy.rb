module Admin
  module Products
    class Destroy
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
        @product = Product.find_by(id: @id)
        unless @product
          @error = "Product not found"
          return self
        end

        # Soft delete: marcar como inactivo
        @product.update(active: false)
        self
      rescue StandardError => e
        @error = "Error deleting product: #{e.message}"
        self
      end

      def success?
        @error.nil?
      end
    end
  end
end

