module Admin
  module CoachVirtual
    module BodyRegions
      class List
        attr_reader :body_regions, :error

        def self.call
          new.call
        end

        def initialize
          @body_regions = []
          @error = nil
        end

        def call
          @body_regions = ::BodyRegion.ordered
          self
        rescue StandardError => e
          Rails.logger.error "Error listing body regions (admin): #{e.message}"
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
end
