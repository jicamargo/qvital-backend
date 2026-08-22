module Admin
  module CoachVirtual
    module Profile
      class Update
        attr_reader :profile, :error, :errors

        def self.call(id:, params:)
          new(id: id, params: params).call
        end

        def initialize(id:, params:)
          @id = id
          @params = params || {}
          @profile = nil
          @error = nil
          @errors = {}
        end

        def call
          @profile = VirtualCoachProfile.find_by(id: @id)
          return failure('Coach Virtual no encontrada') unless @profile

          unless @profile.update(@params)
            @errors = @profile.errors.to_hash
            return failure('No se pudo actualizar la Coach Virtual')
          end

          self
        rescue StandardError => e
          Rails.logger.error "Error updating virtual coach profile: #{e.message}"
          failure('Error inesperado actualizando la Coach Virtual')
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
