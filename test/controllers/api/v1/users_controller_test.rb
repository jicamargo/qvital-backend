require "test_helper"

module Api
  module V1
    class UsersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(email: "users-test-#{SecureRandom.hex(4)}@example.com", role: "cliente",
                              level: Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 })
      end

      test "update_me requires authentication" do
        patch api_v1_users_me_path, params: { name: "Nuevo Nombre" }, as: :json

        assert_response :unauthorized
      end

      test "update_me persists address including addressDetails and locality" do
        stub_authenticated_as(@user) do
          patch api_v1_users_me_path, params: {
            phone: "3001234567",
            address: {
              street: "Calle 1 # 2-34",
              city: "Bogotá D.C.",
              state: "Bogotá D.C.",
              zipCode: "110111",
              addressDetails: "Vereda El Roble, finca La Esperanza, portón azul",
              locality: "Fontibón"
            }
          }, headers: auth_headers, as: :json
        end

        assert_response :success
        user_json = JSON.parse(response.body)["user"]
        assert_equal "3001234567", user_json["phone"]
        assert_equal "Vereda El Roble, finca La Esperanza, portón azul", user_json["address"]["addressDetails"]
        assert_equal "Fontibón", user_json["address"]["locality"]

        @user.reload
        assert_equal "Vereda El Roble, finca La Esperanza, portón azul", @user.address["addressDetails"]
        assert_equal "Fontibón", @user.address["locality"]
      end

      test "update_me ignores unpermitted address keys" do
        stub_authenticated_as(@user) do
          patch api_v1_users_me_path, params: {
            address: { street: "Calle 1", not_allowed: "should be dropped" }
          }, headers: auth_headers, as: :json
        end

        assert_response :success
        @user.reload
        refute @user.address.key?("not_allowed")
      end
    end
  end
end
