module Marketplace
  module Orders
    class List
      attr_reader :orders, :total, :page, :per_page, :error

      def self.call(user:, status: nil, page: 1, per_page: 20)
        new(user:, status:, page:, per_page:).call
      end

      def initialize(user:, status:, page:, per_page:)
        @user = user
        @status = status
        @page = [page.to_i, 1].max
        @per_page = [[per_page.to_i, 1].max, 50].min
        @orders = []
        @total = 0
        @error = nil
      end

      def call
        return failure("User is required") unless @user

        scoped = base_scope
        scoped = apply_status_filter(scoped)
        return self if @error

        @total = scoped.count
        @orders =
          scoped
            .offset((@page - 1) * @per_page)
            .limit(@per_page)

        self
      rescue StandardError => e
        Rails.logger.error "Error listing marketplace orders: #{e.message}"
        failure("Unexpected error listing orders")
      end

      def success?
        @error.nil?
      end

      private

      def base_scope
        Order
          .joins(:purchase)
          .where(purchases: { user_id: @user.id })
          .includes(
            order_items: { product: :category },
            purchase: %i[purchase_intent payments]
          )
          .order(created_at: :desc)
      end

      def apply_status_filter(scope)
        return scope if @status.blank?

        normalized_status = @status.to_s
        return failure("Invalid status filter") unless Order.statuses.key?(normalized_status)

        scope.where(status: normalized_status)
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end
