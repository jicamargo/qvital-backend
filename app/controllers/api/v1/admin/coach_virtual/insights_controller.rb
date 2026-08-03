module Api
  module V1
    module Admin
      module CoachVirtual
        class InsightsController < BaseController
          before_action :authorize_admin!

          # GET /api/v1/admin/coach_virtual/insights
          def index
            result = ::Admin::CoachVirtual::Insights::List.call(params: index_params)

            if result.success?
              render json: BodyEmotionInsightBlueprint.render(result.insights, view: :admin), status: :ok
            else
              render json: { error: result.error }, status: :unprocessable_entity
            end
          end

          # GET /api/v1/admin/coach_virtual/insights/:id
          def show
            result = ::Admin::CoachVirtual::Insights::Show.call(id: params[:id])

            if result.success?
              render json: BodyEmotionInsightBlueprint.render(result.insight, view: :admin), status: :ok
            else
              render json: { error: result.error }, status: :not_found
            end
          end

          # POST /api/v1/admin/coach_virtual/insights
          def create
            result = ::Admin::CoachVirtual::Insights::Create.call(params: insight_params)

            if result.success?
              render json: BodyEmotionInsightBlueprint.render(result.insight, view: :admin), status: :created
            else
              render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
            end
          end

          # PATCH /api/v1/admin/coach_virtual/insights/:id
          def update
            result = ::Admin::CoachVirtual::Insights::Update.call(id: params[:id], params: insight_params)

            if result.success?
              render json: BodyEmotionInsightBlueprint.render(result.insight, view: :admin), status: :ok
            else
              render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
            end
          end

          # DELETE /api/v1/admin/coach_virtual/insights/:id
          def destroy
            result = ::Admin::CoachVirtual::Insights::Destroy.call(id: params[:id])

            if result.success?
              head :no_content
            else
              render json: { error: result.error }, status: :unprocessable_entity
            end
          end

          private

          def authorize_admin!
            unless current_user&.admin?
              render json: { error: 'Forbidden' }, status: :forbidden and return
            end
          end

          def index_params
            params.permit(:body_region_id, :status)
          end

          def insight_params
            params.require(:body_emotion_insight).permit(
              :body_region_id, :symptom_pattern, :emotional_theme, :narrative_explanation,
              :integration_guidance, :severity_flag, :status, :content_curation_notes,
              reflective_questions: [], tags: []
            )
          end
        end
      end
    end
  end
end
