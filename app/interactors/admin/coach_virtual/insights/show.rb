module Admin
  module CoachVirtual
    module Insights
      class Show
        attr_reader :insight, :error

        def self.call(id:)
          new(id: id).call
        end

        def initialize(id:)
          @id = id
          @insight = nil
          @error = nil
        end

        def call
          @insight = ::BodyEmotionInsight.includes(:body_region).find_by(id: @id)
          return failure('Ficha no encontrada') unless @insight

          self
        rescue StandardError => e
          Rails.logger.error "Error loading body emotion insight: #{e.message}"
          failure('Error inesperado cargando la ficha')
        end

        def success?
          @error.nil? && @insight.present?
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
