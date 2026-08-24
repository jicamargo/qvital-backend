module Admin
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
        scope = Recipe.includes(:health_goals)
        scope = scope.where(active: to_bool(@params[:active])) if @params.key?(:active)

        @recipes = scope.order(:title)
        self
      rescue StandardError => e
        @error = "Error listing recipes: #{e.message}"
        self
      end

      def success?
        @error.nil?
      end

      private

      def to_bool(value)
        return true if value == true || value.to_s.downcase == "true"
        return false if value == false || value.to_s.downcase == "false"
        nil
      end
    end
  end
end
