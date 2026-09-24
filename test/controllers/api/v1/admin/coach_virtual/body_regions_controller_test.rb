require "test_helper"

module Api
  module V1
    module Admin
      module CoachVirtual
        class BodyRegionsControllerTest < ActionDispatch::IntegrationTest
          setup do
            @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
            @admin = User.create!(email: "admin-body-regions-#{SecureRandom.hex(4)}@example.com", role: "admin", level: @level)
            @region = BodyRegion.create!(name: "Zona test #{SecureRandom.hex(3)}", body_system: :peso_y_figura)
          end

          test "update sets and clears focus_areas" do
            stub_authenticated_as(@admin) do
              patch api_v1_admin_coach_virtual_body_region_path(@region),
                    params: { body_region: { focus_areas: [ "control_peso" ] } }, headers: auth_headers, as: :json
            end

            assert_response :success
            assert_equal [ "control_peso" ], JSON.parse(response.body)["focus_areas"]
            assert_equal [ "control_peso" ], @region.reload.focus_areas

            stub_authenticated_as(@admin) do
              patch api_v1_admin_coach_virtual_body_region_path(@region),
                    params: { body_region: { focus_areas: [] } }, headers: auth_headers, as: :json
            end

            assert_response :success
            assert_equal [], @region.reload.focus_areas
          end

          test "update rejects an unknown focus_area" do
            stub_authenticated_as(@admin) do
              patch api_v1_admin_coach_virtual_body_region_path(@region),
                    params: { body_region: { focus_areas: [ "no_existe" ] } }, headers: auth_headers, as: :json
            end

            assert_response :unprocessable_entity
            assert_equal [], @region.reload.focus_areas
          end
        end
      end
    end
  end
end
