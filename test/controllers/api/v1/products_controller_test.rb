require "test_helper"

module Api
  module V1
    class ProductsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        @category = Category.find_or_create_by!(name: "Fórmula 1 - Batido Nutricional") { |c| c.position = 1 }
        @user = User.create!(email: "products-test-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)

        @product = Product.create!(name: "Producto de prueba #{SecureRandom.hex(4)}", sku: "TEST-#{SecureRandom.hex(4)}",
                                    category: @category, active: true)
        @product.product_prices.create!(level: @level, price: 100_000)
      end

      test "index requires authentication" do
        get api_v1_products_path, as: :json

        assert_response :unauthorized
      end

      test "index returns the caller's products with price for their level" do
        stub_authenticated_as(@user) do
          get api_v1_products_path, headers: auth_headers, as: :json
        end

        assert_response :success
        products = JSON.parse(response.body)["products"]
        found = products.find { |p| p["id"] == @product.id }
        assert found, "expected product #{@product.id} in the response"
        assert_equal "100000.0", found["price"].to_s
      end

      test "index excludes inactive products" do
        @product.update!(active: false)

        stub_authenticated_as(@user) do
          get api_v1_products_path, headers: auth_headers, as: :json
        end

        assert_response :success
        products = JSON.parse(response.body)["products"]
        refute products.any? { |p| p["id"] == @product.id }
      end

      test "index filters by search query" do
        stub_authenticated_as(@user) do
          get api_v1_products_path, params: { q: "no-existe-#{SecureRandom.hex(6)}" }, headers: auth_headers
        end

        assert_response :success
        products = JSON.parse(response.body)["products"]
        assert_empty products
      end
    end
  end
end
