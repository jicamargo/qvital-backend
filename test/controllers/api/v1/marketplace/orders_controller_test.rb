require "test_helper"

module Api
  module V1
    module Marketplace
      class OrdersControllerTest < ActionDispatch::IntegrationTest
        setup do
          @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @category = Category.find_or_create_by!(name: "Fórmula 1 - Batido Nutricional") { |c| c.position = 1 }
          @user = User.create!(email: "orders-test-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)

          @product = Product.create!(name: "Producto de prueba #{SecureRandom.hex(4)}", sku: "TEST-#{SecureRandom.hex(4)}",
                                      category: @category, active: true)
          @product.product_prices.create!(level: @level, price: 100_000)
        end

        # Barranquilla no tiene localidades/comunas en el catálogo — sirve como
        # ciudad "sin subdivisión" de referencia para los tests que no la involucran.
        def valid_address(overrides = {})
          {
            street: "Calle 1 # 2-34",
            city: "Barranquilla",
            state: "Atlántico",
            zipCode: "080001",
            phone: "3000000000"
          }.merge(overrides)
        end

        def prepare_params(address: valid_address)
          {
            cart_items: [ { product_id: @product.id, quantity: 1, price: "100000.00" } ],
            shipping_address: address,
            recipient_info: { is_different: false, name: "Nombre", last_name: "Apellido" },
            selected_date: (Date.current + 1.day).to_s,
            shipping_cost: "0"
          }
        end

        test "prepare requires authentication" do
          post api_v1_marketplace_orders_prepare_path, params: prepare_params, as: :json

          assert_response :unauthorized
        end

        test "prepare rejects address missing departamento" do
          stub_authenticated_as(@user) do
            post api_v1_marketplace_orders_prepare_path,
                 params: prepare_params(address: valid_address(state: "")),
                 headers: auth_headers, as: :json
          end

          assert_response :unprocessable_entity
          assert_match(/departamento/i, JSON.parse(response.body)["error"])
        end

        test "prepare rejects a city that doesn't belong to the departamento" do
          stub_authenticated_as(@user) do
            post api_v1_marketplace_orders_prepare_path,
                 params: prepare_params(address: valid_address(city: "Medellín")),
                 headers: auth_headers, as: :json
          end

          assert_response :unprocessable_entity
          assert_match(/ciudad/i, JSON.parse(response.body)["error"])
        end

        test "prepare rejects a subdivided city without locality" do
          stub_authenticated_as(@user) do
            post api_v1_marketplace_orders_prepare_path,
                 params: prepare_params(address: valid_address(city: "Bogotá D.C.", state: "Bogotá D.C.")),
                 headers: auth_headers, as: :json
          end

          assert_response :unprocessable_entity
          assert_match(/localidad/i, JSON.parse(response.body)["error"])
        end

        test "prepare rejects an invalid locality for a subdivided city" do
          stub_authenticated_as(@user) do
            post api_v1_marketplace_orders_prepare_path,
                 params: prepare_params(
                   address: valid_address(city: "Bogotá D.C.", state: "Bogotá D.C.", locality: "Not A Real Localidad")
                 ), headers: auth_headers, as: :json
          end

          assert_response :unprocessable_entity
          assert_match(/localidad/i, JSON.parse(response.body)["error"])
        end

        test "prepare accepts a subdivided city with a valid locality" do
          stub_authenticated_as(@user) do
            post api_v1_marketplace_orders_prepare_path,
                 params: prepare_params(
                   address: valid_address(city: "Bogotá D.C.", state: "Bogotá D.C.", locality: "Fontibón")
                 ), headers: auth_headers, as: :json
          end

          assert_response :success
        end

        test "prepare accepts a valid address without locality for a city without subdivisions" do
          stub_authenticated_as(@user) do
            post api_v1_marketplace_orders_prepare_path, params: prepare_params, headers: auth_headers, as: :json
          end

          assert_response :success
        end
      end
    end
  end
end
