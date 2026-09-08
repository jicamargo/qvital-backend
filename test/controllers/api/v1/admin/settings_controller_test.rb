require "test_helper"

module Api
  module V1
    module Admin
      class SettingsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @admin = User.create!(email: "admin-settings-#{SecureRandom.hex(4)}@example.com", role: "admin", level: @level)
          @cliente = User.create!(email: "cliente-settings-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        end

        test "show requires authentication" do
          get api_v1_admin_settings_path, as: :json

          assert_response :unauthorized
        end

        test "show is forbidden for a non-admin user" do
          stub_authenticated_as(@cliente) do
            get api_v1_admin_settings_path, headers: auth_headers, as: :json
          end

          assert_response :forbidden
        end

        test "show returns the current settings, creating the row on first read" do
          assert_difference "AppSetting.count", 1 do
            stub_authenticated_as(@admin) do
              get api_v1_admin_settings_path, headers: auth_headers, as: :json
            end
          end

          assert_response :success
          body = JSON.parse(response.body)
          assert body["premium_purchase_threshold"].present?
        end

        test "update changes the premium purchase threshold" do
          stub_authenticated_as(@admin) do
            patch api_v1_admin_settings_path, params: { setting: { premium_purchase_threshold: "300000" } },
                                               headers: auth_headers, as: :json
          end

          assert_response :success
          assert_equal "300000.0", AppSetting.current.premium_purchase_threshold.to_s
        end

        test "update is forbidden for a non-admin user" do
          stub_authenticated_as(@cliente) do
            patch api_v1_admin_settings_path, params: { setting: { premium_purchase_threshold: "1" } },
                                               headers: auth_headers, as: :json
          end

          assert_response :forbidden
        end

        test "update rejects a non-positive threshold" do
          stub_authenticated_as(@admin) do
            patch api_v1_admin_settings_path, params: { setting: { premium_purchase_threshold: "0" } },
                                               headers: auth_headers, as: :json
          end

          assert_response :unprocessable_entity
          assert JSON.parse(response.body)["details"].key?("premium_purchase_threshold")
        end
      end
    end
  end
end
