module CoachVirtual
  module Consultations
    # Paso "Integra": el usuario elige una de las prácticas de la ficha mostrada
    # y registra si la agregó a sus hábitos (el hábito lo crea el frontend).
    class RegisterPracticeChoice
      attr_reader :consultation, :entry, :error

      def self.call(user:, consultation_id:, title:, added_to_habits:)
        new(user: user, consultation_id: consultation_id, title: title, added_to_habits: added_to_habits).call
      end

      def initialize(user:, consultation_id:, title:, added_to_habits:)
        @user = user
        @consultation_id = consultation_id
        @title = title
        @added_to_habits = ActiveModel::Type::Boolean.new.cast(added_to_habits) || false
        @consultation = nil
        @entry = nil
        @error = nil
      end

      def call
        return failure('Usuario requerido') unless @user

        @consultation = CoachConsultation.for_user(@user.id).find_by(id: @consultation_id)
        return failure('Consulta no encontrada') unless @consultation
        return failure('La consulta ya está cerrada') unless @consultation.abierta?

        ficha = @consultation.coach_consultation_entries.ficha_mostrada.order(:sequence).last
        return failure('Primero elige una zona') unless ficha
        return failure('La práctica no corresponde a la ficha mostrada') unless shown_practice?(ficha)

        next_sequence = (@consultation.coach_consultation_entries.maximum(:sequence) || 0) + 1

        @entry = @consultation.coach_consultation_entries.create!(
          sequence: next_sequence,
          entry_type: :practica_elegida,
          body_region_id: ficha.body_region_id,
          body_emotion_insight_id: ficha.body_emotion_insight_id,
          user_input: @title,
          system_response_payload: { 'added_to_habits' => @added_to_habits }
        )
        self
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages.to_sentence)
      rescue StandardError => e
        Rails.logger.error "Error registering practice choice: #{e.message}"
        failure('Error inesperado guardando tu práctica')
      end

      def success?
        @error.nil?
      end

      private

      def shown_practice?(ficha)
        practices = ficha.system_response_payload&.dig('practices') || ficha.body_emotion_insight&.practices || []
        practices.any? { |practice| practice.is_a?(Hash) && practice['title'] == @title }
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end
