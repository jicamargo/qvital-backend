module CoachVirtual
  module Consultations
    # Paso "Explora": el usuario responde a una de las reflective_questions.
    class RegisterReflectionAnswer
      attr_reader :consultation, :entry, :error

      def self.call(user:, consultation_id:, question:, answer:)
        new(user: user, consultation_id: consultation_id, question: question, answer: answer).call
      end

      def initialize(user:, consultation_id:, question:, answer:)
        @user = user
        @consultation_id = consultation_id
        @question = question
        @answer = answer
        @consultation = nil
        @entry = nil
        @error = nil
      end

      def call
        return failure('Usuario requerido') unless @user
        return failure('La respuesta no puede estar vacía') if @answer.blank?

        @consultation = CoachConsultation.for_user(@user.id).find_by(id: @consultation_id)
        return failure('Consulta no encontrada') unless @consultation
        return failure('La consulta ya está cerrada') unless @consultation.abierta?

        next_sequence = (@consultation.coach_consultation_entries.maximum(:sequence) || 0) + 1

        @entry = @consultation.coach_consultation_entries.create!(
          sequence: next_sequence,
          entry_type: :respuesta_reflexion_usuario,
          user_input: @answer,
          system_response_payload: { 'question' => @question }.compact
        )
        self
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages.to_sentence)
      rescue StandardError => e
        Rails.logger.error "Error registering reflection answer: #{e.message}"
        failure('Error inesperado guardando tu respuesta')
      end

      def success?
        @error.nil?
      end

      private

      def failure(message)
        @error = message
        self
      end
    end
  end
end
