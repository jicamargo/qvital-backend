require "test_helper"

module Api
  module V1
    module Marketplace
      class CartsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @user = User.create!(email: "cart-test-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        end

        test "show requires authentication" do
          get api_v1_marketplace_cart_path, as: :json

          assert_response :unauthorized
        end

        test "show returns null cart when the user has none open" do
          stub_authenticated_as(@user) do
            get api_v1_marketplace_cart_path, headers: auth_headers, as: :json
          end

          assert_response :success
          assert_nil JSON.parse(response.body)["cart"]
        end

        test "show returns the user's open cart" do
          cart = Cart.create!(user: @user, status: :open)

          stub_authenticated_as(@user) do
            get api_v1_marketplace_cart_path, headers: auth_headers, as: :json
          end

          assert_response :success
          body = JSON.parse(response.body)["cart"]
          assert_equal cart.id, body["id"]
          assert_equal [], body["cart_items"]
        end

        test "show does not return another user's cart" do
          other_user = User.create!(email: "cart-other-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
          Cart.create!(user: other_user, status: :open)

          stub_authenticated_as(@user) do
            get api_v1_marketplace_cart_path, headers: auth_headers, as: :json
          end

          assert_response :success
          assert_nil JSON.parse(response.body)["cart"]
        end
      end
    end
  end
end
