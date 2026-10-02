module CoachVirtual
  module Insights
    # Demo gratuita de la Brújula Corporal: expone solo el tema emocional, la
    # explicación y la PRIMERA pregunta reflexiva. Nunca las demás preguntas,
    # prácticas, guía de integración ni campos de curaduría.
    class Preview
      attr_reader :preview, :error, :not_found

      def self.call(user:, body_region_id:)
        new(user: user, body_region_id: body_region_id).call
      end

      def initialize(user:, body_region_id:)
        @user = user
        @body_region_id = body_region_id
        @preview = nil
        @error = nil
        @not_found = false
      end

      def call
        region = BodyRegion.active.find_by(id: @body_region_id)
        return not_found_failure unless region

        found = FindForRegion.call(body_region_id: region.id)
        return failure(found.error) unless found.success?

        insight = found.insight
        return self unless insight

        record_view(region)
        @preview = build_preview(region, insight)
        self
      rescue StandardError => e
        Rails.logger.error "Error building body emotion preview: #{e.message}"
        failure("Error inesperado preparando la demo")
      end

      def success?
        @error.nil?
      end

      private

      def build_preview(region, insight)
        questions = Array(insight.reflective_questions)
        {
          body_region: { id: region.id, name: region.name },
          emotional_theme: insight.emotional_theme,
          narrative_explanation: insight.narrative_explanation,
          first_question: questions.first,
          has_more_questions: questions.size > 1,
          severity_flag: insight.severity_flag
        }
      end

      # Medir la demo nunca debe impedir mostrarla.
      def record_view(region)
        CoachDemoView.create!(user: @user, body_region: region)
      rescue StandardError => e
        Rails.logger.error "Could not record coach demo view: #{e.class.name} - #{e.message}"
      end

      def not_found_failure
        @not_found = true
        failure("Zona no encontrada")
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end
