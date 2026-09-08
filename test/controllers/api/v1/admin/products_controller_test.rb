require "test_helper"

module Api
  module V1
    module Admin
      class ProductsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @category = Category.find_or_create_by!(name: "Fórmula 1 - Batido Nutricional") { |c| c.position = 1 }
          @admin = User.create!(email: "admin-test-#{SecureRandom.hex(4)}@example.com", role: "admin", level: @level)
          @cliente = User.create!(email: "cliente-test-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
          @product = Product.create!(name: "Producto admin #{SecureRandom.hex(4)}", sku: "ADM-#{SecureRandom.hex(4)}",
                                      category: @category)
        end

        test "index requires authentication" do
          get api_v1_admin_products_path, as: :json

          assert_response :unauthorized
        end

        test "index is forbidden for a non-admin user" do
          stub_authenticated_as(@cliente) do
            get api_v1_admin_products_path, headers: auth_headers, as: :json
          end

          assert_response :forbidden
        end

        test "index returns products for an admin" do
          stub_authenticated_as(@admin) do
            get api_v1_admin_products_path, headers: auth_headers, as: :json
          end

          assert_response :success
          products = JSON.parse(response.body)
          assert products.any? { |p| p["id"] == @product.id }
        end

        test "create adds a product with prices when the caller is admin" do
          params = {
            product: {
              name: "Producto nuevo #{SecureRandom.hex(4)}",
              category_id: @category.id,
              active: true,
              prices: { @level.id.to_s => "50000" }
            }
          }

          assert_difference "Product.count", 1 do
            stub_authenticated_as(@admin) do
              post api_v1_admin_products_path, params: params, headers: auth_headers, as: :json
            end
          end

          assert_response :created
          body = JSON.parse(response.body)
          assert_equal params[:product][:name], body["name"]
        end

        test "create is forbidden for a non-admin user" do
          params = { product: { name: "No debería crearse" } }

          assert_no_difference "Product.count" do
            stub_authenticated_as(@cliente) do
              post api_v1_admin_products_path, params: params, headers: auth_headers, as: :json
            end
          end

          assert_response :forbidden
        end

        test "update changes product attributes" do
          params = { product: { name: "Nombre actualizado" } }

          stub_authenticated_as(@admin) do
            patch api_v1_admin_product_path(@product), params: params, headers: auth_headers, as: :json
          end

          assert_response :success
          assert_equal "Nombre actualizado", @product.reload.name
        end

        test "destroy soft-deletes the product (marks it inactive)" do
          assert_no_difference "Product.count" do
            stub_authenticated_as(@admin) do
              delete api_v1_admin_product_path(@product), headers: auth_headers, as: :json
            end
          end

          assert_response :no_content
          refute @product.reload.active?
        end
      end
    end
  end
end
