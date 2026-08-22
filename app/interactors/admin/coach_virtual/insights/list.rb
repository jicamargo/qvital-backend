module Admin
  module CoachVirtual
    module Insights
      class List
        attr_reader :insights, :error

        def self.call(params: {})
          new(params: params).call
        end

        def initialize(params: {})
          @params = params || {}
          @insights = []
          @error = nil
        end

        def call
          scope = ::BodyEmotionInsight.includes(:body_region).order(:body_region_id, :id)
          scope = scope.where(body_region_id: @params[:body_region_id]) if @params[:body_region_id].present?
          scope = scope.where(status: @params[:status]) if @params[:status].present?

          @insights = scope
          self
        rescue StandardError => e
          Rails.logger.error "Error listing body emotion insights: #{e.message}"
          failure('Error inesperado cargando las fichas')
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
