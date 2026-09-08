require "test_helper"

module Api
  module V1
    module Admin
      class UsersControllerTest < ActionDispatch::IntegrationTest
        setup do
          @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @admin = User.create!(email: "admin-users-#{SecureRandom.hex(4)}@example.com", role: "admin", level: @level)
          @cliente = User.create!(email: "cliente-users-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        end

        test "show requires authentication" do
          get api_v1_admin_user_path(@cliente), as: :json

          assert_response :unauthorized
        end

        test "show is forbidden for a non-admin user" do
          stub_authenticated_as(@cliente) do
            get api_v1_admin_user_path(@cliente), headers: auth_headers, as: :json
          end

          assert_response :forbidden
        end

        test "show returns the requested user for an admin" do
          stub_authenticated_as(@admin) do
            get api_v1_admin_user_path(@cliente), headers: auth_headers, as: :json
          end

          assert_response :success
          assert_equal @cliente.id, JSON.parse(response.body)["id"]
        end

        test "show returns 404 for a non-existent user" do
          stub_authenticated_as(@admin) do
            get api_v1_admin_user_path(id: 0), headers: auth_headers, as: :json
          end

          assert_response :not_found
        end

        test "update sets premium_active and premium_expires_at" do
          expires_at = 30.days.from_now.iso8601

          stub_authenticated_as(@admin) do
            patch api_v1_admin_user_path(@cliente),
                  params: { user: { premium_active: true, premium_expires_at: expires_at } },
                  headers: auth_headers, as: :json
          end

          assert_response :success
          @cliente.reload
          assert @cliente.premium_active
          assert_equal expires_at, @cliente.premium_expires_at.iso8601
        end

        test "update is forbidden for a non-admin user" do
          stub_authenticated_as(@cliente) do
            patch api_v1_admin_user_path(@cliente), params: { user: { premium_active: true } },
                                                     headers: auth_headers, as: :json
          end

          assert_response :forbidden
        end

        test "update rejects an invalid role" do
          stub_authenticated_as(@admin) do
            patch api_v1_admin_user_path(@cliente), params: { user: { role: "not-a-role" } },
                                                     headers: auth_headers, as: :json
          end

          assert_response :unprocessable_entity
        end

        test "destroy removes a user with no purchase/cart history" do
          assert_difference "User.count", -1 do
            stub_authenticated_as(@admin) do
              delete api_v1_admin_user_path(@cliente), headers: auth_headers, as: :json
            end
          end

          assert_response :no_content
        end

        test "destroy is forbidden for a non-admin user" do
          stub_authenticated_as(@cliente) do
            delete api_v1_admin_user_path(@admin), headers: auth_headers, as: :json
          end

          assert_response :forbidden
        end

        test "destroy refuses to remove a user with purchase history" do
          purchase_intent = PurchaseIntent.create!(user: @cliente, external_reference: SecureRandom.uuid, total_amount: 100)
          Purchase.create!(
            purchase_intent:, user: @cliente, total_amount: 100, subtotal_amount: 100,
            tax_amount: 0, shipping_cost: 0, purchase_number: "PUR-#{SecureRandom.hex(6)}"
          )

          assert_no_difference "User.count" do
            stub_authenticated_as(@admin) do
              delete api_v1_admin_user_path(@cliente), headers: auth_headers, as: :json
            end
          end

          assert_response :unprocessable_entity
          assert_match(/historial/i, JSON.parse(response.body)["error"])
        end
      end
    end
  end
end
