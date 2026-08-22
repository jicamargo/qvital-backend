module CoachVirtual
  module Consultations
    class List
      attr_reader :consultations, :error

      def self.call(user:)
        new(user: user).call
      end

      def initialize(user:)
        @user = user
        @consultations = []
        @error = nil
      end

      def call
        return failure('Usuario requerido') unless @user

        @consultations = CoachConsultation.for_user(@user.id)
                                           .includes(:virtual_coach_profile, coach_consultation_entries: :body_region)
                                           .recent_first
        self
      rescue StandardError => e
        Rails.logger.error "Error listing coach consultations: #{e.message}"
        failure('Error inesperado cargando tu historial')
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
