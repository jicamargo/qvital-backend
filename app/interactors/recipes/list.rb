module Recipes
  class List
    attr_reader :recipes, :error

    def self.call(params: {})
      new(params: params).call
    end

    def initialize(params: {})
      @params = params || {}
      @recipes = Recipe.none
      @error = nil
    end

    def call
      scope = Recipe.active.includes(:health_goals)
      scope = scope.by_health_goal_key(@params[:health_goal_key]) if @params[:health_goal_key].present?
      scope = scope.by_product_id(@params[:product_id]) if @params[:product_id].present?
      scope = scope.where(difficulty: @params[:difficulty]) if @params[:difficulty].present?
      scope = scope.where(recipe_type: @params[:recipe_type]) if @params[:recipe_type].present?
      scope = scope.where("prep_time_minutes <= ?", @params[:max_prep_time].to_i) if @params[:max_prep_time].present?

      @recipes = scope.order(:title)
      self
    rescue StandardError => e
      @error = "Error listing recipes: #{e.message}"
      self
    end

    def success?
      @error.nil?
    end
  end
end
