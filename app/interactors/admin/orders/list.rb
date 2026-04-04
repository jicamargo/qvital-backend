module Admin
  module Orders
    class List
      attr_reader :orders, :total, :page, :per_page, :error

      def self.call(status: nil, page: 1, per_page: 20, search: nil, from: nil, to: nil)
        new(status:, page:, per_page:, search:, from:, to:).call
      end

      def initialize(status:, page:, per_page:, search:, from:, to:)
        @status = status
        @page = [page.to_i, 1].max
        @per_page = [[per_page.to_i, 1].max, 50].min
        @search = search
        @from = from
        @to = to
        @orders = []
        @total = 0
        @error = nil
      end

      def call
        scoped = base_scope
        scoped = apply_status_filter(scoped)
        return self if @error

        scoped = apply_date_filters(scoped)
        return self if @error

        scoped = apply_search_filter(scoped)

        @total = scoped.count
        @orders =
          scoped
            .order(created_at: :desc)
            .offset((@page - 1) * @per_page)
            .limit(@per_page)

        self
      rescue StandardError => e
        Rails.logger.error "Error listing admin orders: #{e.message}"
        failure("Unexpected error listing orders")
      end

      def success?
        @error.nil?
      end

      private

      def base_scope
        Order.includes(
          order_items: { product: :category },
          purchase: %i[user purchase_intent payments]
        )
      end

      def apply_status_filter(scope)
        return scope if @status.blank?

        normalized = @status.to_s
        return failure("Invalid status filter") unless Order.statuses.key?(normalized)

        scope.where(status: normalized)
      end

      def apply_date_filters(scope)
        if @from.present?
          parsed = parse_date_start(@from)
          return failure("Invalid from date") unless parsed

          scope = scope.where(created_at: parsed..)
        end

        if @to.present?
          parsed = parse_date_end(@to)
          return failure("Invalid to date") unless parsed

          scope = scope.where(created_at: ..parsed)
        end

        scope
      end

      def parse_date_start(value)
        Time.zone.parse(value.to_s)
      rescue ArgumentError, TypeError
        nil
      end

      def parse_date_end(value)
        t = Time.zone.parse(value.to_s)
        t&.end_of_day
      rescue ArgumentError, TypeError
        nil
      end

      def apply_search_filter(scope)
        return scope if @search.blank?

        term = "%#{ActiveRecord::Base.sanitize_sql_like(@search.to_s.strip)}%"
        ids = []
        ids.concat(Order.joins(purchase: :user).where("users.email ILIKE ?", term).pluck(:id))
        ids.concat(Order.joins(:purchase).where("purchases.purchase_number ILIKE ?", term).pluck(:id))
        ids.concat(
          Order.joins(purchase: :purchase_intent).where(
            "purchase_intents.external_reference ILIKE ?",
            term
          ).pluck(:id)
        )

        scope.where(id: ids.uniq)
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end
