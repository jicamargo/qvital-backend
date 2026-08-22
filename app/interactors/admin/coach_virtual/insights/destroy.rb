module Admin
  module CoachVirtual
    module Insights
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
          insight = ::BodyEmotionInsight.find_by(id: @id)
          return failure('Ficha no encontrada') unless insight

          insight.destroy!
          self
        rescue StandardError => e
          Rails.logger.error "Error destroying body emotion insight: #{e.message}"
          failure('Error inesperado eliminando la ficha')
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
