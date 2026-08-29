module Api
  module V1
    class RecipesController < BaseController
      # GET /api/v1/recipes
      def index
        result = ::Recipes::List.call(params: index_params)

        if result.success?
          render json: {
            recipes: RecipeBlueprint.render_as_hash(result.recipes, view: :default),
            pagination: { page: result.page, per_page: result.per_page, total: result.total }
          }, status: :ok
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/recipes/for_me
      def for_me
        result = ::Recipes::ListForUser.call(user: current_user)

        if result.success?
          render json: RecipeBlueprint.render(result.recipes, view: :default), status: :ok
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/recipes/:slug
      def show
        result = ::Recipes::Show.call(slug: params[:slug])

        if result.success?
          render json: RecipeBlueprint.render(result.recipe, view: :detail), status: :ok
        else
          render json: { error: result.error }, status: :not_found
        end
      end

      private

      def index_params
        params.permit(:health_goal_key, :difficulty, :max_prep_time, :product_id, :recipe_type,
                      :max_calories, :search, :page, :per_page)
      end
    end
  end
end
