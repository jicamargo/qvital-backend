module CoachVirtual
  module Consultations
    class Start
      attr_reader :consultation, :error

      def self.call(user:)
        new(user: user).call
      end

      def initialize(user:)
        @user = user
        @consultation = nil
        @error = nil
      end

      def call
        return failure('Usuario requerido') unless @user

        profile = VirtualCoachProfile.current
        return failure('No hay una Coach Virtual activa configurada') unless profile

        @consultation = CoachConsultation.create!(
          user: @user,
          virtual_coach_profile: profile,
          started_at: Time.current,
          status: :abierta
        )
        self
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages.to_sentence)
      rescue StandardError => e
        Rails.logger.error "Error starting coach consultation: #{e.message}"
        failure('Error inesperado iniciando la consulta')
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
