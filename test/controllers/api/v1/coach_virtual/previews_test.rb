require "test_helper"

module Api
  module V1
    module CoachVirtual
      class PreviewsTest < ActionDispatch::IntegrationTest
        setup do
          level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @user = User.create!(email: "preview-ctrl-#{SecureRandom.hex(4)}@example.com", role: "cliente",
                               level: level, premium_active: false)
          @region = BodyRegion.create!(name: "Zona preview #{SecureRandom.hex(3)}", body_system: :digestivo)
          @empty_region = BodyRegion.create!(name: "Zona vacía #{SecureRandom.hex(3)}", body_system: :digestivo)
          @inactive_region = BodyRegion.create!(name: "Zona inactiva #{SecureRandom.hex(3)}", body_system: :digestivo, active: false)
          BodyEmotionInsight.create!(
            body_region: @region, status: :publicado, symptom_pattern: "Hinchazón",
            emotional_theme: "Tensión contenida", narrative_explanation: "Explicación breve",
            integration_guidance: "Guía secreta",
            reflective_questions: [ "Primera pregunta visible?", "Segunda pregunta oculta?", "Tercera pregunta oculta?" ],
            practices: [
              { "title" => "Práctica uno oculta", "description" => "Descripción uno." },
              { "title" => "Práctica dos oculta", "description" => "Descripción dos." }
            ]
          )
        end

        def get_preview(region_id)
          stub_authenticated_as(@user) do
            get api_v1_coach_virtual_preview_path(region_id), headers: auth_headers
          end
        end

        test "preview returns limited content to a non-premium user" do
          get_preview(@region.id)

          assert_response :success
          preview = JSON.parse(response.body)["preview"]
          assert_equal %w[body_region emotional_theme narrative_explanation first_question has_more_questions severity_flag].sort,
                       preview.keys.sort
          assert_equal "Primera pregunta visible?", preview["first_question"]
          assert_equal true, preview["has_more_questions"]
          assert_equal @region.id, preview["body_region"]["id"]
          assert_not_includes response.body, "Segunda pregunta oculta"
          assert_not_includes response.body, "Tercera pregunta oculta"
          assert_not_includes response.body, "Práctica uno oculta"
          assert_not_includes response.body, "Práctica dos oculta"
          assert_not_includes response.body, "Guía secreta"
        end

        test "preview records a demo view" do
          assert_difference -> { CoachDemoView.count }, 1 do
            get_preview(@region.id)
          end

          view = CoachDemoView.order(:id).last
          assert_equal @user.id, view.user_id
          assert_equal @region.id, view.body_region_id
        end

        test "preview still answers when recording the view fails" do
          original = CoachDemoView.method(:create!)
          CoachDemoView.define_singleton_method(:create!) { |*| raise ActiveRecord::ActiveRecordError, "boom" }
          begin
            get_preview(@region.id)
          ensure
            CoachDemoView.define_singleton_method(:create!, original)
          end

          assert_response :success
          assert_equal "Primera pregunta visible?", JSON.parse(response.body)["preview"]["first_question"]
        end

        test "preview is null when the zone has no published insight" do
          get_preview(@empty_region.id)

          assert_response :success
          assert_equal({ "preview" => nil }, JSON.parse(response.body))
        end

        test "preview 404 for missing or inactive zone" do
          get_preview(@inactive_region.id)
          assert_response :not_found
          assert_equal "Zona no encontrada", JSON.parse(response.body)["error"]

          get_preview(0)
          assert_response :not_found
        end

        test "preview requires authentication" do
          get api_v1_coach_virtual_preview_path(@region.id)

          assert_response :unauthorized
        end
      end
    end
  end
end
