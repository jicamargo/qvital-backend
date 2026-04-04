module Admin
  module Orders
    class Update
      attr_reader :order, :error, :errors

      def self.call(id:, params:)
        new(id:, params:).call
      end

      def initialize(id:, params:)
        @id = id
        @params = (params || {}).to_h.with_indifferent_access
        @order = nil
        @error = nil
        @errors = {}
      end

      def call
        @order = Order.find_by(id: @id)
        return failure("Order not found") unless @order

        if @params.key?(:status) && @params[:status].present?
          normalized = @params[:status].to_s
          unless Order.statuses.key?(normalized)
            return failure("Invalid status")
          end

          @order.status = normalized
        end

        if @params.key?(:shipping_date_estimated)
          @order.shipping_date_estimated = parse_datetime(@params[:shipping_date_estimated])
        end

        if @params.key?(:shipping_date_real)
          @order.shipping_date_real = parse_datetime(@params[:shipping_date_real])
        end

        if @params.key?(:tracking_info)
          @order.tracking_info = normalize_tracking(@params[:tracking_info])
        end

        unless @order.save
          @errors = @order.errors.to_hash
          return failure("Validation failed")
        end

        self
      rescue StandardError => e
        Rails.logger.error "Error updating admin order: #{e.message}"
        failure("Unexpected error updating order")
      end

      def success?
        @error.nil?
      end

      private

      def parse_datetime(value)
        return nil if value.blank?

        Time.zone.parse(value.to_s)
      rescue ArgumentError, TypeError, RangeError
        nil
      end

      def normalize_tracking(value)
        return {} if value.nil?

        hash =
          if value.respond_to?(:to_unsafe_h)
            value.to_unsafe_h
          elsif value.is_a?(Hash)
            value
          else
            {}
          end

        hash.deep_stringify_keys
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end
