module Admin
  module Orders
    class Update
      attr_reader :order, :error, :errors

      # Estados que significan "esto se pagó y se está despachando".
      ADVANCED_STATUSES = %w[confirmed shipped delivered].freeze

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

          if ADVANCED_STATUSES.include?(normalized) && !@order.purchase.payments.approved.exists?
            return failure("La orden no tiene un pago aprobado. Verifica el pago en Wompi antes de avanzarla.")
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

        send_shipped_email

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

      TRACKING_KEYS = %w[carrier tracking_number tracking_url].freeze

      # Solo guarda transportadora, número y enlace (strings sin espacios
      # sobrantes). El enlace se descarta si no es http/https.
      def normalize_tracking(value)
        hash =
          if value.respond_to?(:to_unsafe_h)
            value.to_unsafe_h
          elsif value.is_a?(Hash)
            value
          else
            {}
          end

        cleaned = hash.stringify_keys.slice(*TRACKING_KEYS).transform_values { |v| v.is_a?(String) ? v.strip : nil }
        cleaned.delete("tracking_url") unless cleaned["tracking_url"].to_s.match?(%r{\Ahttps?://\S+\z}i)
        cleaned.reject { |_, v| v.blank? }
      end

      # Avisa al cliente una sola vez cuando el pedido pasa a "shipped".
      # Un fallo al encolar el correo no debe hacer fallar la actualización.
      def send_shipped_email
        return unless @order.shipped? && @order.shipped_notified_at.nil?
        return if @order.purchase.user&.email.blank?

        @order.update_column(:shipped_notified_at, Time.current)
        begin
          OrderMailer.shipped(@order).deliver_later
        rescue StandardError => e
          Rails.logger.error "Error enqueuing shipped email for order #{@order.id}: #{e.message}"
        end
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end
