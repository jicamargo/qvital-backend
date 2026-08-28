module Admin
  module Recipes
    class Create
      attr_reader :recipe, :error, :errors

      def self.call(params:)
        new(params: params).call
      end

      def initialize(params:)
        @params = params || {}
        @recipe = nil
        @error = nil
        @errors = {}
      end

      def call
        ActiveRecord::Base.transaction do
          @recipe = Recipe.new(recipe_attributes)
          unless @recipe.save
            @errors = @recipe.errors.to_hash
            raise ActiveRecord::Rollback
          end

          assign_ingredients!
          assign_health_goals!
        end

        self
      rescue StandardError => e
        @error ||= "Error creating recipe: #{e.message}"
        self
      end

      def success?
        @error.nil? && @recipe&.persisted?
      end

      private

      def recipe_attributes
        @params.slice(:title, :slug, :description, :servings, :prep_time_minutes, :difficulty, :instructions, :image_url, :active,
                      :recipe_type, :calories, :protein_g, :carbs_g, :fat_g, :fiber_g, :tips, :source)
      end

      def assign_ingredients!
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
        return unless @params.key?(:health_goal_ids)

        @recipe.health_goal_ids = Array(@params[:health_goal_ids])
      end
    end
  end
end
