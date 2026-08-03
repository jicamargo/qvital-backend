module Admin
  module CoachVirtual
    module Insights
      class Create
        attr_reader :insight, :error, :errors

        def self.call(params:)
          new(params: params).call
        end

        def initialize(params:)
          @params = params || {}
          @insight = nil
          @error = nil
          @errors = {}
        end

        def call
          @insight = ::BodyEmotionInsight.new(@params)

          unless @insight.save
            @errors = @insight.errors.to_hash
            return failure('No se pudo crear la ficha')
          end

          self
        rescue StandardError => e
          Rails.logger.error "Error creating body emotion insight: #{e.message}"
          failure('Error inesperado creando la ficha')
        end

        def success?
          @error.nil? && @insight&.persisted?
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
