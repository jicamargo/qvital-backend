module CoachVirtual
  module Consultations
    class Show
      attr_reader :consultation, :error

      def self.call(user:, consultation_id:)
        new(user: user, consultation_id: consultation_id).call
      end

      def initialize(user:, consultation_id:)
        @user = user
        @consultation_id = consultation_id
        @consultation = nil
        @error = nil
      end

      def call
        return failure('Usuario requerido') unless @user

        @consultation = CoachConsultation.for_user(@user.id)
                                          .includes(:virtual_coach_profile, coach_consultation_entries: :body_emotion_insight)
                                          .find_by(id: @consultation_id)
        return failure('Consulta no encontrada') unless @consultation

        self
      rescue StandardError => e
        Rails.logger.error "Error loading coach consultation: #{e.message}"
        failure('Error inesperado cargando la consulta')
      end

      def success?
        @error.nil? && @consultation.present?
      end

      private

      def failure(message)
        @error = message
        self
      end
    end
  end
end
