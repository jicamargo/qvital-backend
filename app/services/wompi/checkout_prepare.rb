module Wompi
  class CheckoutPrepare
    Result = Struct.new(
      :amount_in_cents,
      :reference,
      :checkout_url,
      :fields,
      :error,
      keyword_init: true
    )

    def self.call(purchase:, payer:, shipping_address:, recipient_info:, expiration_time: nil)
      new(
        purchase:,
        payer:,
        shipping_address:,
        recipient_info:,
        expiration_time:
      ).call
    end

    def initialize(purchase:, payer:, shipping_address:, recipient_info:, expiration_time:)
      @purchase = purchase
      @payer = payer || {}
      @shipping_address = shipping_address || {}
      @recipient_info = recipient_info || {}
      @expiration_time = expiration_time
    end

    def call
      return Result.new(error: "WOMPI_PUBLIC_KEY is not configured") if Wompi::Config.public_key.blank?

      amount_in_cents = (BigDecimal(@purchase.total_amount.to_s) * 100).to_i
      reference = @purchase.purchase_intent.external_reference
      currency = "COP"
      signature =
        Wompi::Signature.checkout_integrity(
          reference:,
          amount_in_cents:,
          currency:,
          expiration_time: @expiration_time
        )

      fields = {
        "public-key" => Wompi::Config.public_key,
        "currency" => currency,
        "amount-in-cents" => amount_in_cents.to_s,
        "reference" => reference,
        "signature:integrity" => signature
      }
      fields["redirect-url"] = Wompi::Config.redirect_url if Wompi::Config.redirect_url.present?
      fields["expiration-time"] = @expiration_time if @expiration_time.present?

      attach_customer_fields!(fields)
      attach_shipping_fields!(fields)

      Result.new(
        amount_in_cents:,
        reference:,
        checkout_url: Wompi::Config.checkout_url,
        fields:
      )
    rescue StandardError => e
      Result.new(error: e.message)
    end

    private

    def attach_customer_fields!(fields)
      fields["customer-data:email"] = @payer[:email].to_s if @payer[:email].present?
      fields["customer-data:full-name"] = @payer[:name].to_s if @payer[:name].present?
      fields["customer-data:phone-number"] = @payer[:phone].to_s if @payer[:phone].present?
      fields["customer-data:phone-number-prefix"] = "+57" if @payer[:phone].present?
      fields["customer-data:legal-id"] = @payer[:document].to_s if @payer[:document].present?
      fields["customer-data:legal-id-type"] = "CC" if @payer[:document].present?
    end

    def attach_shipping_fields!(fields)
      return if @shipping_address.blank?

      recipient_name = @recipient_info[:name].presence || @payer[:name].presence

      fields["collect-shipping"] = "true"
      fields["shipping-address:address-line-1"] = @shipping_address[:street].to_s
      fields["shipping-address:country"] = "CO"
      fields["shipping-address:city"] = @shipping_address[:city].to_s
      fields["shipping-address:region"] = @shipping_address[:state].to_s
      fields["shipping-address:phone-number"] = @shipping_address[:phone].to_s
      fields["shipping-address:name"] = recipient_name.to_s if recipient_name.present?
      fields["shipping-address:postal-code"] = @shipping_address[:zipCode].to_s if @shipping_address[:zipCode].present?
    end
  end
end
