module Products
  class ListForUser
    attr_reader :products, :error

    def self.call(user:, health_goal_key: nil)
      new(user: user, health_goal_key: health_goal_key).call
    end

    def initialize(user:, health_goal_key: nil)
      @user = user
      @health_goal_key = health_goal_key
      @products = []
      @error = nil
    end

    def call
      return failure('User is required') unless @user
      return failure('User level is required to calculate prices') unless @user.level_id

      load_products_for_level
      self
    rescue StandardError => e
      @error = "Unexpected error loading products: #{e.message}"
      Rails.logger.error @error
      self
    end

    def success?
      @error.nil?
    end

    private

    def load_products_for_level
      level_id = @user.level_id

      scope =
        Product
          .active
          .joins(:product_prices, :category)
          .where(product_prices: { level_id: level_id })
          .includes(:category, :product_prices, :health_goals)
          .order('categories.position ASC, products.name ASC')
          .distinct

      scope = scope.by_health_goal_key(@health_goal_key) if @health_goal_key.present?

      @products = scope
    rescue StandardError => e
      failure("Error querying products: #{e.message}")
    end

    def failure(message)
      @error = message
      self
    end
  end
end

