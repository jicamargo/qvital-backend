require "test_helper"

module CoachVirtual
  class RegisterPracticeChoiceTest < ActiveSupport::TestCase
    PRACTICE_TITLE = "Pausa antes de comer".freeze

    setup do
      level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
      @user = User.create!(email: "practice-choice-#{SecureRandom.hex(4)}@example.com", role: "cliente",
                           level: level, premium_active: true)
      @region = BodyRegion.create!(name: "Zona práctica #{SecureRandom.hex(3)}", body_system: :digestivo)
      @insight = BodyEmotionInsight.create!(
        body_region: @region, status: :publicado, symptom_pattern: "Hinchazón", emotional_theme: "Tensión",
        narrative_explanation: "Texto", integration_guidance: "Guía",
        practices: [ { "title" => PRACTICE_TITLE, "description" => "Respira lento tres veces antes del primer bocado." } ]
      )
      @consultation = Consultations::Start.call(user: @user).consultation
    end

    def select_zone!
      Consultations::RegisterZoneSelection.call(user: @user, consultation_id: @consultation.id, body_region_id: @region.id)
    end

    def choose(title: PRACTICE_TITLE, added_to_habits: true, user: @user, consultation_id: @consultation.id)
      Consultations::RegisterPracticeChoice.call(user: user, consultation_id: consultation_id, title: title,
                                                 added_to_habits: added_to_habits)
    end

    test "registers the chosen practice" do
      select_zone!

      result = choose

      assert result.success?
      entry = @consultation.coach_consultation_entries.order(:sequence).last
      assert_equal "practica_elegida", entry.entry_type
      assert_equal PRACTICE_TITLE, entry.user_input
      assert_equal true, entry.system_response_payload["added_to_habits"]
      assert_equal @insight.id, entry.body_emotion_insight_id
    end

    test "casts added_to_habits strings" do
      select_zone!

      result = choose(added_to_habits: "false")

      assert result.success?
      assert_equal false, result.entry.system_response_payload["added_to_habits"]
    end

    test "fails when title is not one of the shown practices" do
      select_zone!

      result = choose(title: "Otra cosa")

      assert_not result.success?
      assert_equal "La práctica no corresponde a la ficha mostrada", result.error
    end

    test "fails on closed consultation" do
      select_zone!
      Consultations::Close.call(user: @user, consultation_id: @consultation.id)

      result = choose

      assert_equal "La consulta ya está cerrada", result.error
    end

    test "fails for another user's consultation" do
      select_zone!
      other = User.create!(email: "practice-other-#{SecureRandom.hex(4)}@example.com", role: "cliente",
                           level: @user.level, premium_active: true)

      result = choose(user: other)

      assert_equal "Consulta no encontrada", result.error
    end

    test "fails when no insight was shown yet" do
      result = choose

      assert_equal "Primero elige una zona", result.error
    end
  end
end
