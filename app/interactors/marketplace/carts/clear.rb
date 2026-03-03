module Marketplace
  module Carts
    class Clear
      attr_reader :cart, :error

      def self.call(user:)
        new(user: user).call
      end

      def initialize(user:)
        @user = user
        @cart = nil
        @error = nil
      end

      def call
        return failure('User is required') unless @user

        ActiveRecord::Base.transaction do
          @cart =
            Cart
              .with_marketplace_includes
              .for_user(@user.id)
              .open
              .order(created_at: :desc)
              .first
          return failure('Open cart not found') unless @cart

          @cart.cart_items.destroy_all
        end

        self
      rescue StandardError => e
        Rails.logger.error "Error clearing cart: #{e.message}"
        failure('Unexpected error clearing cart')
      end

      def success?
        @error.nil?
      end

      private

      def failure(message)
        @error = message
        self
      end
    end
  end
end

