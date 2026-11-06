require "test_helper"

module Api
  module V1
    module Marketplace
      class CartsRepeatControllerTest < ActionDispatch::IntegrationTest
        setup do
          @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @user = User.create!(email: "repeat-ctl-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        end

        def confirmed_purchase_with(*products)
          intent = PurchaseIntent.create!(user: @user, external_reference: SecureRandom.uuid, total_amount: 1)
          purchase = Purchase.create!(
            purchase_intent: intent, user: @user, total_amount: 1, subtotal_amount: 1, tax_amount: 0,
            shipping_cost: 0, purchase_number: "PUR-#{SecureRandom.hex(6)}", status: :confirmed
          )
          products.each do |product|
            PurchaseItem.create!(
              purchase: purchase, product: product, quantity: 2, unit_price: 1,
              line_subtotal: 2, line_tax: 0, line_total: 2
            )
          end
        end

        test "requires authentication" do
          post repeat_last_order_api_v1_marketplace_cart_path, as: :json

          assert_response :unauthorized
        end

        test "returns the cart and the skipped names" do
          product = Product.create!(name: "Batido #{SecureRandom.hex(3)}", active: true)
          product.product_prices.create!(level: @level, price: 80_000)
          inactive = Product.create!(name: "Retirado #{SecureRandom.hex(3)}", active: false)
          confirmed_purchase_with(product, inactive)

          stub_authenticated_as(@user) do
            post repeat_last_order_api_v1_marketplace_cart_path, headers: auth_headers, as: :json
          end

          assert_response :success
          body = JSON.parse(response.body)
          assert_equal [ product.id ], body["cart"]["cart_items"].map { |i| i["product_id"] || i.dig("product", "id") }
          assert_equal [ inactive.name ], body["skipped"]
        end

        test "returns 422 when there are no confirmed purchases" do
          stub_authenticated_as(@user) do
            post repeat_last_order_api_v1_marketplace_cart_path, headers: auth_headers, as: :json
          end

          assert_response :unprocessable_entity
          assert_equal "Aún no tienes pedidos para repetir.", JSON.parse(response.body)["error"]
        end
      end
    end
  end
end
