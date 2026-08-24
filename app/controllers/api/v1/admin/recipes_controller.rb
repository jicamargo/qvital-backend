module Api
  module V1
    module Admin
      class RecipesController < BaseController
        before_action :authorize_admin!

        def index
          result = ::Admin::Recipes::List.call(params: index_params)

          if result.success?
            render json: RecipeBlueprint.render(result.recipes, view: :admin), status: :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end

        def show
          result = ::Admin::Recipes::Show.call(id: params[:id])

          if result.success?
            render json: RecipeBlueprint.render(result.recipe, view: :admin), status: :ok
          else
            render json: { error: result.error }, status: :not_found
          end
        end

        def create
          result = ::Admin::Recipes::Create.call(params: recipe_params)

          if result.success?
            render json: RecipeBlueprint.render(result.recipe, view: :admin), status: :created
          else
            render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
          end
        end

        def update
          result = ::Admin::Recipes::Update.call(id: params[:id], params: recipe_params)

          if result.success?
            render json: RecipeBlueprint.render(result.recipe, view: :admin), status: :ok
          else
            render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
          end
        end

        def destroy
          result = ::Admin::Recipes::Destroy.call(id: params[:id])

          if result.success?
            head :no_content
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end

        private

        def authorize_admin!
          unless current_user&.admin?
            render json: { error: "Forbidden" }, status: :forbidden and return
          end
        end

        def index_params
          params.permit(:active)
        end

        def recipe_params
          params.require(:recipe).permit(
            :title,
            :slug,
            :description,
            :servings,
            :prep_time_minutes,
            :difficulty,
            :image_url,
            :active,
            instructions: [],
            health_goal_ids: [],
            recipe_ingredients: [ :product_id, :generic_name, :quantity, :is_optional, :position ]
          )
        end
      end
    end
  end
end
