require "test_helper"

module Api
  module V1
    module Marketplace
      class CheckoutControllerTest < ActionDispatch::IntegrationTest
        setup do
          @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @user = User.create!(email: "checkout-status-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        end

        def build_approved_purchase(total_amount:, premium_granted:)
          purchase_intent =
            PurchaseIntent.create!(user: @user, external_reference: SecureRandom.uuid, total_amount:)
          purchase =
            Purchase.create!(
              purchase_intent:, user: @user, total_amount:, subtotal_amount: total_amount,
              tax_amount: 0, shipping_cost: 0, purchase_number: "PUR-#{SecureRandom.hex(6)}",
              premium_granted:
            )
          Payment.create!(
            purchase:, external_reference: purchase_intent.external_reference,
            provider: "wompi", provider_payment_id: "wompi-#{SecureRandom.hex(6)}",
            status: :approved, amount: total_amount, currency: "COP"
          )
        end

        test "status requires authentication" do
          get api_v1_marketplace_checkout_status_path, params: { transaction_id: "anything" }

          assert_response :unauthorized
        end

        test "status includes premium info when this purchase granted it" do
          @user.update!(premium_active: true, premium_expires_at: 30.days.from_now)
          payment = build_approved_purchase(total_amount: 150_000, premium_granted: true)

          stub_authenticated_as(@user) do
            get api_v1_marketplace_checkout_status_path, params: { transaction_id: payment.provider_payment_id },
                                                          headers: auth_headers
          end

          assert_response :success
          premium = JSON.parse(response.body)["premium"]
          assert premium["granted"]
          assert premium["active"]
          assert premium["expires_at"].present?
        end

        test "status reports premium not granted for a purchase below the threshold" do
          payment = build_approved_purchase(total_amount: 50_000, premium_granted: false)

          stub_authenticated_as(@user) do
            get api_v1_marketplace_checkout_status_path, params: { transaction_id: payment.provider_payment_id },
                                                          headers: auth_headers
          end

          assert_response :success
          premium = JSON.parse(response.body)["premium"]
          refute premium["granted"]
        end
      end
    end
  end
end
