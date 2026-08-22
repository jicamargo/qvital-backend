module Admin
  module CoachVirtual
    module BodyRegions
      class Show
        attr_reader :body_region, :error

        def self.call(id:)
          new(id: id).call
        end

        def initialize(id:)
          @id = id
          @body_region = nil
          @error = nil
        end

        def call
          @body_region = ::BodyRegion.find_by(id: @id)
          return failure('Zona del cuerpo no encontrada') unless @body_region

          self
        rescue StandardError => e
          Rails.logger.error "Error loading body region: #{e.message}"
          failure('Error inesperado cargando la zona del cuerpo')
        end

        def success?
          @error.nil? && @body_region.present?
        end

        private

        def failure(message)
          @error = message
          self
        end
      end
    end
  end
end
