module Admin
  module CoachVirtual
    module BodyRegions
      class Create
        attr_reader :body_region, :error, :errors

        def self.call(params:)
          new(params: params).call
        end

        def initialize(params:)
          @params = params || {}
          @body_region = nil
          @error = nil
          @errors = {}
        end

        def call
          @body_region = ::BodyRegion.new(@params)

          unless @body_region.save
            @errors = @body_region.errors.to_hash
            return failure('No se pudo crear la zona del cuerpo')
          end

          self
        rescue StandardError => e
          Rails.logger.error "Error creating body region: #{e.message}"
          failure('Error inesperado creando la zona del cuerpo')
        end

        def success?
          @error.nil? && @body_region&.persisted?
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
