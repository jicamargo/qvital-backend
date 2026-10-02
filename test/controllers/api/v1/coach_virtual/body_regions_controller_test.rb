require "test_helper"

module Api
  module V1
    module CoachVirtual
      class BodyRegionsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @user = User.create!(email: "body-regions-test-#{SecureRandom.hex(4)}@example.com", role: "cliente",
                               level: @level, premium_active: true)
          # La DB de test puede traer zonas reales (docs/database.md): nombres únicos y
          # aserciones de inclusión/exclusión en vez de listas exactas.
          @weight_zone = BodyRegion.create!(name: "Peso test #{SecureRandom.hex(3)}", body_system: :peso_y_figura,
                                            focus_areas: [ "control_peso" ])
          @other_zone = BodyRegion.create!(name: "Otra test #{SecureRandom.hex(3)}", body_system: :cabeza_cuello)
          @inactive_weight_zone = BodyRegion.create!(name: "Inactiva test #{SecureRandom.hex(3)}", body_system: :peso_y_figura,
                                                     focus_areas: [ "control_peso" ], active: false)
        end

        test "index returns all active regions with their focus_areas" do
          stub_authenticated_as(@user) do
            get api_v1_coach_virtual_body_regions_path, headers: auth_headers
          end

          assert_response :success
          regions = JSON.parse(response.body)["body_regions"]
          names = regions.map { |r| r["name"] }
          assert_includes names, @weight_zone.name
          assert_includes names, @other_zone.name
          assert_equal [ "control_peso" ], regions.find { |r| r["name"] == @weight_zone.name }["focus_areas"]
          assert_equal [], regions.find { |r| r["name"] == @other_zone.name }["focus_areas"]
        end

        test "index filters by focus_area" do
          stub_authenticated_as(@user) do
            get api_v1_coach_virtual_body_regions_path, params: { focus_area: "control_peso" }, headers: auth_headers
          end

          assert_response :success
          regions = JSON.parse(response.body)["body_regions"]
          names = regions.map { |r| r["name"] }
          assert_includes names, @weight_zone.name
          refute_includes names, @other_zone.name
          refute_includes names, @inactive_weight_zone.name
          assert(regions.all? { |r| r["focus_areas"].include?("control_peso") })
        end

        test "index rejects an unknown focus_area" do
          stub_authenticated_as(@user) do
            get api_v1_coach_virtual_body_regions_path, params: { focus_area: "no_existe" }, headers: auth_headers
          end

          assert_response :unprocessable_entity
          assert_equal "Enfoque no válido", JSON.parse(response.body)["error"]
        end
      end
    end
  end
end
