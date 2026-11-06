require "test_helper"

module Api
  module V1
    module Admin
      class LevelsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @cliente_level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @vip_level = Level.find_or_create_by!(name: "Cliente VIP") { |l| l.priority = 2 }
          @admin = User.create!(email: "admin-levels-#{SecureRandom.hex(4)}@example.com", role: "admin", level: @cliente_level)
          @cliente = User.create!(email: "cliente-levels-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @cliente_level)
        end

        test "requires authentication" do
          get api_v1_admin_levels_path, as: :json

          assert_response :unauthorized
        end

        test "is forbidden for a non-admin user" do
          stub_authenticated_as(@cliente) do
            get api_v1_admin_levels_path, headers: auth_headers, as: :json
          end

          assert_response :forbidden
        end

        test "lists the levels ordered by priority" do
          stub_authenticated_as(@admin) do
            get api_v1_admin_levels_path, headers: auth_headers, as: :json
          end

          assert_response :success
          levels = JSON.parse(response.body)
          assert_equal Level.order(:priority).pluck(:name), levels.map { |l| l["name"] }
          assert_equal %w[id name priority], levels.first.keys.sort
        end
      end
    end
  end
end
