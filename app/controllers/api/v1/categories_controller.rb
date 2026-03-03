module Api
  module V1
    class CategoriesController < BaseController
      # GET /api/v1/categories
      def index
        result = ::Categories::List.call

        if result.success?
          categories_json = JSON.parse(CategoryBlueprint.render(result.categories))
          render json: { categories: categories_json }, status: :ok
        else
          render json: { error: result.error || 'Unable to load categories' }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Categories index error: #{e.class.name} - #{e.message}"
        render json: { error: 'Internal server error' }, status: :internal_server_error
      end
    end
  end
end

