module Products
  class ListForUser
    attr_reader :products, :error

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
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

      @products =
        Product
          .active
          .joins(:product_prices, :category)
          .where(product_prices: { level_id: level_id })
          .includes(:category, :product_prices)
          .order('categories.position ASC, products.name ASC')
          .distinct
    rescue StandardError => e
      failure("Error querying products: #{e.message}")
    end

    def failure(message)
      @error = message
      self
    end
  end
end

