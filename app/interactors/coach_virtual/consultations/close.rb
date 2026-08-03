module CoachVirtual
  module Consultations
    class Close
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

        @consultation = CoachConsultation.for_user(@user.id).find_by(id: @consultation_id)
        return failure('Consulta no encontrada') unless @consultation

        @consultation.update!(status: :cerrada, ended_at: Time.current) if @consultation.abierta?
        self
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages.to_sentence)
      rescue StandardError => e
        Rails.logger.error "Error closing coach consultation: #{e.message}"
        failure('Error inesperado cerrando la consulta')
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
