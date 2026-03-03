module Marketplace
  module Carts
    class FetchOpen
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

        @cart =
          Cart
            .with_marketplace_includes
            .for_user(@user.id)
            .open
            .order(created_at: :desc)
            .first
        self
      rescue StandardError => e
        Rails.logger.error "Error fetching open cart: #{e.message}"
        failure('Unexpected error loading cart')
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

