module Admin
  module Recipes
    class Update
      attr_reader :recipe, :error, :errors

      def self.call(id:, params:)
        new(id: id, params: params).call
      end

      def initialize(id:, params:)
        @id = id
        @params = params || {}
        @recipe = nil
        @error = nil
        @errors = {}
      end

      def call
        ActiveRecord::Base.transaction do
          @recipe = Recipe.find_by(id: @id)
          unless @recipe
            @error = "Recipe not found"
            raise ActiveRecord::Rollback
          end

          unless @recipe.update(recipe_attributes)
            @errors = @recipe.errors.to_hash
            raise ActiveRecord::Rollback
          end

          assign_ingredients! if @params.key?(:recipe_ingredients)
          assign_health_goals! if @params.key?(:health_goal_ids)
        end

        self
      rescue StandardError => e
        @error ||= "Error updating recipe: #{e.message}"
        self
      end

      def success?
        @error.nil? && @recipe.present?
      end

      private

      def recipe_attributes
        @params.slice(:title, :slug, :description, :servings, :prep_time_minutes, :difficulty, :instructions, :image_url,
                      :image_path, :active, :recipe_type, :calories, :protein_g, :carbs_g, :fat_g, :fiber_g, :tips, :source)
      end

      # Reemplaza todos los ingredientes en vez de diffear por id — un
      # recurso admin de bajo volumen no justifica esa complejidad extra.
      def assign_ingredients!
        @recipe.recipe_ingredients.destroy_all

        ingredients = @params[:recipe_ingredients]
        return unless ingredients.is_a?(Array)

        ingredients.each_with_index do |attrs, index|
          ingredient = @recipe.recipe_ingredients.build(
            product_id: attrs[:product_id],
            generic_name: attrs[:generic_name],
            quantity: attrs[:quantity],
            is_optional: attrs[:is_optional] || false,
            position: attrs[:position] || index
          )
          unless ingredient.save
            @errors[:recipe_ingredients] ||= []
            @errors[:recipe_ingredients] << ingredient.errors.to_hash
            raise ActiveRecord::Rollback
          end
        end
      end

      def assign_health_goals!
        @recipe.health_goal_ids = Array(@params[:health_goal_ids])
      end
    end
  end
end
