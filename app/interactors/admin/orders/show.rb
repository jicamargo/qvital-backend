module Admin
  module Orders
    class Show
      attr_reader :order, :error

      def self.call(id:)
        new(id:).call
      end

      def initialize(id:)
        @id = id
        @order = nil
        @error = nil
      end

      def call
        @order =
          Order
            .includes(
              order_items: { product: :category },
              purchase: [
                :purchase_intent,
                :payments,
                { user: :level },
                { purchase_items: { product: :category } }
              ]
            )
            .find_by(id: @id)

        return failure("Order not found") unless @order

        self
      rescue StandardError => e
        Rails.logger.error "Error loading admin order: #{e.message}"
        failure("Unexpected error loading order")
      end

      def success?
        @error.nil?
      end

      private

      def failure(message)
        @error = message
        self
      end
    end
  end
end
