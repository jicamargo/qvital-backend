module Admin
  module Products
    class Create
      attr_reader :product, :error, :errors

      def self.call(params:)
        new(params: params).call
      end

      def initialize(params:)
        @params = params || {}
        @product = nil
        @error = nil
        @errors = {}
      end

      def call
        ActiveRecord::Base.transaction do
          @product = Product.new(product_attributes)
          unless @product.save
            @errors = @product.errors.to_hash
            raise ActiveRecord::Rollback
          end

          assign_prices!
        end

        self
      rescue StandardError => e
        @error ||= "Error creating product: #{e.message}"
        self
      end

      def success?
        @error.nil? && @product&.persisted?
      end

      private

      def product_attributes
        @params.slice(:name, :description, :image_url, :image_path, :sku, :pv, :category_id, :active)
      end

      def assign_prices!
        prices = @params[:prices]
        return unless prices.is_a?(Hash)

        prices.each do |level_key, price|
          next if price.blank?

          level = find_level(level_key)
          next unless level

          product_price = @product.product_prices.find_or_initialize_by(level: level)
          product_price.price = price
          unless product_price.save
            @errors[:product_prices] ||= []
            @errors[:product_prices] << product_price.errors.to_hash
            raise ActiveRecord::Rollback
          end
        end
      end

      def find_level(key)
        if key.to_s =~ /^\d+$/
          Level.find_by(id: key.to_i)
        else
          Level.find_by(name: key.to_s)
        end
      end
    end
  end
end

