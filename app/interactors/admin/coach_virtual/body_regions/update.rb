module Admin
  module CoachVirtual
    module BodyRegions
      class Update
        attr_reader :body_region, :error, :errors

        def self.call(id:, params:)
          new(id: id, params: params).call
        end

        def initialize(id:, params:)
          @id = id
          @params = params || {}
          @body_region = nil
          @error = nil
          @errors = {}
        end

        def call
          @body_region = ::BodyRegion.find_by(id: @id)
          return failure('Zona del cuerpo no encontrada') unless @body_region

          unless @body_region.update(@params)
            @errors = @body_region.errors.to_hash
            return failure('No se pudo actualizar la zona del cuerpo')
          end

          self
        rescue StandardError => e
          Rails.logger.error "Error updating body region: #{e.message}"
          failure('Error inesperado actualizando la zona del cuerpo')
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
