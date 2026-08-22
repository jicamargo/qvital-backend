module CoachVirtual
  module Profile
    class Show
      attr_reader :profile, :error

      def self.call
        new.call
      end

      def initialize
        @profile = nil
        @error = nil
      end

      def call
        @profile = VirtualCoachProfile.current
        return failure('No hay una Coach Virtual activa configurada') unless @profile

        self
      rescue StandardError => e
        Rails.logger.error "Error loading virtual coach profile: #{e.message}"
        failure('Error inesperado cargando la Coach Virtual')
      end

      def success?
        @error.nil? && @profile.present?
      end

      private

      def failure(message)
        @error = message
        self
      end
    end
  end
end
