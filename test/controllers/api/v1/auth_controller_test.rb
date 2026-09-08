require "test_helper"

module Api
  module V1
    class AuthControllerTest < ActionDispatch::IntegrationTest
      test "sync without a token is unauthorized" do
        post api_v1_auth_sync_path, as: :json

        assert_response :unauthorized
      end

      test "sync with a valid token returns the synced user" do
        user = User.create!(email: "auth-test-#{SecureRandom.hex(4)}@example.com", role: "cliente",
                             level: Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 })

        stub_authenticated_as(user) do
          post api_v1_auth_sync_path, headers: auth_headers, as: :json
        end

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal user.id, body["user"]["id"]
        assert_equal user.email, body["user"]["email"]
      end

      test "sync with an invalid token is unauthorized" do
        failed_result = Struct.new(:user, :error) do
          def success?
            false
          end
        end.new(nil, "Invalid token: signature verification failed")

        stub_sync_user(failed_result) do
          post api_v1_auth_sync_path, headers: auth_headers, as: :json
        end

        assert_response :unauthorized
      end
    end
  end
end
