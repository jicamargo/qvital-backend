module Admin
  module Recipes
    class Destroy
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
        @recipe = Recipe.find_by(id: @id)
        unless @recipe
          @error = "Recipe not found"
          return self
        end

        # Soft delete: igual criterio que productos/objetivos de salud.
        @recipe.update(active: false)
        self
      rescue StandardError => e
        @error = "Error deleting recipe: #{e.message}"
        self
      end

      def success?
        @error.nil?
      end
    end
  end
end
