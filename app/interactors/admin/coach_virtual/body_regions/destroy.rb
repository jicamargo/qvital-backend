module Admin
  module CoachVirtual
    module BodyRegions
      class Destroy
        attr_reader :error

        def self.call(id:)
          new(id: id).call
        end

        def initialize(id:)
          @id = id
          @error = nil
        end

        def call
          body_region = ::BodyRegion.find_by(id: @id)
          return failure('Zona del cuerpo no encontrada') unless body_region

          unless body_region.destroy
            return failure(body_region.errors.full_messages.to_sentence.presence || 'No se pudo eliminar la zona del cuerpo')
          end

          self
        rescue StandardError => e
          Rails.logger.error "Error destroying body region: #{e.message}"
          failure('Error inesperado eliminando la zona del cuerpo')
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
end
