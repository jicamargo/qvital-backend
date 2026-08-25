module Recipes
  class Show
    attr_reader :recipe, :error

    def self.call(slug:)
      new(slug: slug).call
    end

    def initialize(slug:)
      @slug = slug
      @recipe = nil
      @error = nil
    end

    def call
      @recipe = Recipe.active.includes(:health_goals, recipe_ingredients: :product).find_by(slug: @slug)
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
