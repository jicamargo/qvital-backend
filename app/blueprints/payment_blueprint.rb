class PaymentBlueprint < Blueprinter::Base
  identifier :id

  fields :external_reference,
         :provider,
         :provider_payment_id,
         :provider_preference_id,
         :status,
         :amount,
         :currency,
         :raw_payload,
         :created_at,
         :updated_at
end

