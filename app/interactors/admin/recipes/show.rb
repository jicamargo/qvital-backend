module Admin
  module Recipes
    class Show
      attr_reader :recipe, :error

      def self.call(id:)
        new(id: id).call
      end

      def initialize(id:)
        @id = id
        @recipe = nil
        @error = nil
      end

      def call
        @recipe = Recipe.includes(:health_goals, recipe_ingredients: :product).find_by(id: @id)
        @error = "Recipe not found" unless @recipe
        self
      rescue StandardError => e
        @error = "Error loading recipe: #{e.message}"
        self
      end

      def success?
        @error.nil?
      end
    end
  end
end
