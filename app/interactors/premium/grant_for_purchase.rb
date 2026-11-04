module Premium
  # Días de Premium que otorga una compra pagada. Se acumulan: si a la clienta
  # le quedan días, los nuevos se suman al vencimiento actual.
  #
  #   - Beneficio por monto: si el subtotal de los productos físicos llega al
  #     umbral (Admin > Configuración) se otorgan THRESHOLD_DAYS. El plan
  #     Premium (producto digital) no cuenta para el umbral.
  #   - Productos digitales: premium_days x cantidad.
  #
  # Devuelve los días otorgados (0 si ninguno).
  class GrantForPurchase
    THRESHOLD_DAYS = 30

    def self.call(purchase:, now: Time.current)
      new(purchase:, now:).call
    end

    def initialize(purchase:, now:)
      @purchase = purchase
      @now = now
    end

    def call
      user = @purchase.user
      return 0 unless user

      days = threshold_days + digital_days
      return 0 unless days.positive?

      base = [ @now, user.premium_expires_at ].compact.max
      @purchase.update!(premium_granted: true)
      user.update!(premium_active: true, premium_expires_at: base + days.days)
      days
    end

    private

    def items
      @items ||= @purchase.purchase_items.includes(:product).to_a
    end

    def threshold_days
      physical_subtotal = items.reject { |i| i.product.digital? }.sum(&:line_subtotal)
      physical_subtotal >= AppSetting.current.premium_purchase_threshold ? THRESHOLD_DAYS : 0
    end

    def digital_days
      items.select { |i| i.product.digital? }.sum { |i| i.product.premium_days * i.quantity }
    end
  end
end
