module Admin
  module CoachVirtual
    module Insights
      class Update
        attr_reader :insight, :error, :errors

        def self.call(id:, params:)
          new(id: id, params: params).call
        end

        def initialize(id:, params:)
          @id = id
          @params = params || {}
          @insight = nil
          @error = nil
          @errors = {}
        end

        def call
          @insight = ::BodyEmotionInsight.find_by(id: @id)
          return failure('Ficha no encontrada') unless @insight

          unless @insight.update(@params)
            @errors = @insight.errors.to_hash
            return failure('No se pudo actualizar la ficha')
          end

          self
        rescue StandardError => e
          Rails.logger.error "Error updating body emotion insight: #{e.message}"
          failure('Error inesperado actualizando la ficha')
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
