module CoachVirtual
  module Consultations
    # Paso "Ubica" -> "Explora": registra la zona elegida (+ síntoma libre
    # opcional) y busca/registra la ficha de conocimiento correspondiente,
    # todo en una sola transacción para mantener la secuencia de entries
    # consistente en el historial.
    class RegisterZoneSelection
      attr_reader :consultation, :entries, :insight, :error

      def self.call(user:, consultation_id:, body_region_id:, user_input: nil)
        new(
          user: user,
          consultation_id: consultation_id,
          body_region_id: body_region_id,
          user_input: user_input
        ).call
      end

      def initialize(user:, consultation_id:, body_region_id:, user_input: nil)
        @user = user
        @consultation_id = consultation_id
        @body_region_id = body_region_id
        @user_input = user_input.presence
        @consultation = nil
        @entries = []
        @insight = nil
        @error = nil
      end

      def call
        return failure('Usuario requerido') unless @user
        return failure('Zona del cuerpo requerida') if @body_region_id.blank?

        @consultation = CoachConsultation.for_user(@user.id).find_by(id: @consultation_id)
        return failure('Consulta no encontrada') unless @consultation
        return failure('La consulta ya está cerrada') unless @consultation.abierta?

        body_region = BodyRegion.active.find_by(id: @body_region_id)
        return failure('Zona del cuerpo no encontrada') unless body_region

        ActiveRecord::Base.transaction do
          next_sequence = (@consultation.coach_consultation_entries.maximum(:sequence) || 0)

          zone_entry = @consultation.coach_consultation_entries.create!(
            sequence: next_sequence + 1,
            entry_type: :zona_seleccionada,
            body_region: body_region
          )
          @entries << zone_entry

          if @user_input
            symptom_entry = @consultation.coach_consultation_entries.create!(
              sequence: next_sequence + 2,
              entry_type: :sintoma_descrito_usuario,
              body_region: body_region,
              user_input: @user_input
            )
            @entries << symptom_entry
          end

          @insight = CoachVirtual::Insights::FindForRegion.call(body_region_id: body_region.id).insight

          if @insight
            insight_entry = @consultation.coach_consultation_entries.create!(
              sequence: (@entries.last.sequence + 1),
              entry_type: :ficha_mostrada,
              body_region: body_region,
              body_emotion_insight: @insight,
              system_response_payload: insight_snapshot(@insight)
            )
            @entries << insight_entry
          end
        end

        self
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages.to_sentence)
      rescue StandardError => e
        Rails.logger.error "Error registering zone selection: #{e.message}"
        failure('Error inesperado registrando la zona seleccionada')
      end

      def success?
        @error.nil?
      end

      private

      # Snapshot del contenido mostrado en el momento (además del FK), para que
      # el historial no cambie si la ficha se edita/archiva después.
      def insight_snapshot(insight)
        {
          'symptom_pattern' => insight.symptom_pattern,
          'emotional_theme' => insight.emotional_theme,
          'narrative_explanation' => insight.narrative_explanation,
          'reflective_questions' => insight.reflective_questions,
          'integration_guidance' => insight.integration_guidance,
          'severity_flag' => insight.severity_flag
        }
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end
