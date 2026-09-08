require "test_helper"

module Api
  module V1
    class SettingsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        @user = User.create!(email: "settings-test-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
      end

      test "show requires authentication" do
        get api_v1_settings_path

        assert_response :unauthorized
      end

      test "show returns the premium purchase threshold for a non-admin user" do
        AppSetting.current.update!(premium_purchase_threshold: 175_000)

        stub_authenticated_as(@user) do
          get api_v1_settings_path, headers: auth_headers
        end

        assert_response :success
        assert_equal "175000.0", JSON.parse(response.body)["premium_purchase_threshold"]
      end
    end
  end
end
