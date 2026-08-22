module CoachVirtual
  module Insights
    # MVP: selección por curación manual (primera ficha publicada de la zona).
    # Fase 2 (agente IA) reemplazará este matching por ranking vía RAG,
    # ver docs/requirements/coach-cuerpo-emocion-sdd.md §8 (frontend repo).
    class FindForRegion
      attr_reader :insight, :error

      def self.call(body_region_id:)
        new(body_region_id: body_region_id).call
      end

      def initialize(body_region_id:)
        @body_region_id = body_region_id
        @insight = nil
        @error = nil
      end

      def call
        return failure('Zona del cuerpo requerida') if @body_region_id.blank?

        @insight = BodyEmotionInsight.published
                                     .where(body_region_id: @body_region_id)
                                     .order(:id)
                                     .first
        self
      rescue StandardError => e
        Rails.logger.error "Error finding body emotion insight: #{e.message}"
        failure('Error inesperado buscando contenido para esa zona')
      end

      # No encontrar ficha NO es un error: la zona puede no tener contenido
      # publicado todavía (estado vacío en frontend).
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
