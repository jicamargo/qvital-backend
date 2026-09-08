require "test_helper"

module Api
  module V1
    class CategoriesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(email: "categories-test-#{SecureRandom.hex(4)}@example.com", role: "cliente",
                              level: Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 })
      end

      test "index requires authentication" do
        get api_v1_categories_path, as: :json

        assert_response :unauthorized
      end

      test "index returns categories ordered by position when authenticated" do
        Category.find_or_create_by!(name: "Zzz Categoria") { |c| c.position = 99 }
        Category.find_or_create_by!(name: "Fórmula 1 - Batido Nutricional") { |c| c.position = 1 }

        stub_authenticated_as(@user) do
          get api_v1_categories_path, headers: auth_headers, as: :json
        end

        assert_response :success
        categories = JSON.parse(response.body)["categories"]
        positions = categories.map { |c| c["position"] }
        assert_equal positions.sort, positions
      end
    end
  end
end
