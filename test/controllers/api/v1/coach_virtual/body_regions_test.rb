require "test_helper"

module Api
  module V1
    module CoachVirtual
      class BodyRegionsTest < ActionDispatch::IntegrationTest
        setup do
          level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @user = User.create!(email: "regions-ctrl-#{SecureRandom.hex(4)}@example.com", role: "cliente",
                               level: level, premium_active: false)
        end

        test "index is available to non-premium users" do
          stub_authenticated_as(@user) do
            get api_v1_coach_virtual_body_regions_path, headers: auth_headers
          end

          assert_response :success
          assert JSON.parse(response.body).key?("body_regions")
        end

        test "consultations stay premium-only" do
          stub_authenticated_as(@user) do
            post api_v1_coach_virtual_consultations_path, headers: auth_headers, as: :json
          end

          assert_response :forbidden
        end
      end
    end
  end
end
