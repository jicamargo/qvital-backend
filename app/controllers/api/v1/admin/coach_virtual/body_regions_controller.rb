module Api
  module V1
    module Admin
      module CoachVirtual
        class BodyRegionsController < BaseController
          before_action :authorize_admin!

          # GET /api/v1/admin/coach_virtual/body_regions
          def index
            result = ::Admin::CoachVirtual::BodyRegions::List.call

            if result.success?
              render json: BodyRegionBlueprint.render(result.body_regions, view: :admin), status: :ok
            else
              render json: { error: result.error }, status: :unprocessable_entity
            end
          end

          # GET /api/v1/admin/coach_virtual/body_regions/:id
          def show
            result = ::Admin::CoachVirtual::BodyRegions::Show.call(id: params[:id])

            if result.success?
              render json: BodyRegionBlueprint.render(result.body_region, view: :admin), status: :ok
            else
              render json: { error: result.error }, status: :not_found
            end
          end

          # POST /api/v1/admin/coach_virtual/body_regions
          def create
            result = ::Admin::CoachVirtual::BodyRegions::Create.call(params: body_region_params)

            if result.success?
              render json: BodyRegionBlueprint.render(result.body_region, view: :admin), status: :created
            else
              render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
            end
          end

          # PATCH /api/v1/admin/coach_virtual/body_regions/:id
          def update
            result = ::Admin::CoachVirtual::BodyRegions::Update.call(id: params[:id], params: body_region_params)

            if result.success?
              render json: BodyRegionBlueprint.render(result.body_region, view: :admin), status: :ok
            else
              render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
            end
          end

          # DELETE /api/v1/admin/coach_virtual/body_regions/:id
          def destroy
            result = ::Admin::CoachVirtual::BodyRegions::Destroy.call(id: params[:id])

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

          def body_region_params
            params.require(:body_region).permit(:name, :parent_id, :body_system, :display_order, :illustration_ref, :active)
          end
        end
      end
    end
  end
end
