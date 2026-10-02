require "test_helper"

module Api
  module V1
    module CoachVirtual
      class PracticeChoicesTest < ActionDispatch::IntegrationTest
        setup do
          level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
          @user = User.create!(email: "practice-ctrl-#{SecureRandom.hex(4)}@example.com", role: "cliente",
                               level: level, premium_active: true)
          region = BodyRegion.create!(name: "Zona ctrl #{SecureRandom.hex(3)}", body_system: :digestivo)
          BodyEmotionInsight.create!(
            body_region: region, status: :publicado, symptom_pattern: "Hinchazón", emotional_theme: "Tensión",
            narrative_explanation: "Texto", integration_guidance: "Guía",
            practices: [ { "title" => "Pausa antes de comer", "description" => "Respira lento tres veces antes del primer bocado." } ]
          )
          @consultation = ::CoachVirtual::Consultations::Start.call(user: @user).consultation
          ::CoachVirtual::Consultations::RegisterZoneSelection.call(
            user: @user, consultation_id: @consultation.id, body_region_id: region.id
          )
        end

        test "registers the practice choice and returns the consultation" do
          stub_authenticated_as(@user) do
            post practice_choices_api_v1_coach_virtual_consultation_path(@consultation),
                 params: { practice_choice: { title: "Pausa antes de comer", added_to_habits: true } },
                 headers: auth_headers, as: :json
          end

          assert_response :success
          entries = JSON.parse(response.body)["consultation"]["coach_consultation_entries"]
          assert_includes entries.map { |e| e["entry_type"] }, "practica_elegida"
        end

        test "returns 422 for an invalid title" do
          stub_authenticated_as(@user) do
            post practice_choices_api_v1_coach_virtual_consultation_path(@consultation),
                 params: { practice_choice: { title: "Inventada", added_to_habits: false } },
                 headers: auth_headers, as: :json
          end

          assert_response :unprocessable_entity
          assert_equal "La práctica no corresponde a la ficha mostrada", JSON.parse(response.body)["error"]
        end

        test "requires premium" do
          @user.update!(premium_active: false)

          stub_authenticated_as(@user) do
            post practice_choices_api_v1_coach_virtual_consultation_path(@consultation),
                 params: { practice_choice: { title: "Pausa antes de comer", added_to_habits: true } },
                 headers: auth_headers, as: :json
          end

          assert_response :forbidden
        end
      end
    end
  end
end
