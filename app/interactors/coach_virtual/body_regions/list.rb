module CoachVirtual
  module BodyRegions
    # Zonas activas para el paso "Ubica". `focus_area` (opcional) filtra por un
    # enfoque transversal, p. ej. "control_peso" (Peso y emociones).
    class List
      attr_reader :body_regions, :error

      def self.call(focus_area: nil)
        new(focus_area: focus_area).call
      end

      def initialize(focus_area: nil)
        @focus_area = focus_area.presence
        @body_regions = []
        @error = nil
      end

      def call
        if @focus_area && BodyRegion::FOCUS_AREAS.exclude?(@focus_area)
          return failure('Enfoque no válido')
        end

        scope = BodyRegion.active.ordered
        scope = scope.with_focus_area(@focus_area) if @focus_area
        @body_regions = scope
        self
      rescue StandardError => e
        Rails.logger.error "Error listing body regions: #{e.message}"
        failure('Error inesperado cargando las zonas del cuerpo')
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
