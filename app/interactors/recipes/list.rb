module Recipes
  class List
    MAX_PER_PAGE = 50
    DEFAULT_PER_PAGE = 12

    attr_reader :recipes, :total, :page, :per_page, :error

    def self.call(params: {})
      new(params: params).call
    end

    def initialize(params: {})
      @params = params || {}
      @recipes = Recipe.none
      @page = [ @params[:page].to_i, 1 ].max
      requested_per_page = @params[:per_page].present? ? @params[:per_page].to_i : DEFAULT_PER_PAGE
      @per_page = [ [ requested_per_page, 1 ].max, MAX_PER_PAGE ].min
      @total = 0
      @error = nil
    end

    def call
      scope = Recipe.active.includes(:health_goals)
      scope = scope.by_health_goal_key(@params[:health_goal_key]) if @params[:health_goal_key].present?
      scope = scope.by_product_id(@params[:product_id]) if @params[:product_id].present?
      scope = scope.where(difficulty: @params[:difficulty]) if @params[:difficulty].present?
      scope = scope.where(recipe_type: @params[:recipe_type]) if @params[:recipe_type].present?
      scope = scope.where("prep_time_minutes <= ?", @params[:max_prep_time].to_i) if @params[:max_prep_time].present?
      scope = scope.where("calories <= ?", @params[:max_calories].to_i) if @params[:max_calories].present?
      scope = apply_search(scope)

      @total = scope.count
      @recipes = scope.order(:title).offset((@page - 1) * @per_page).limit(@per_page)
      self
    rescue StandardError => e
      @error = "Error listing recipes: #{e.message}"
      self
    end

    def success?
      @error.nil?
    end

    private

    def apply_search(scope)
      return scope unless @params[:search].present?

      term = "%#{@params[:search].to_s.strip}%"
      scope.where("recipes.title ILIKE :term OR recipes.description ILIKE :term", term: term)
    end
  end
end
