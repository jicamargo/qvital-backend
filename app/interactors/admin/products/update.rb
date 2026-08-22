module Admin
  module Products
    class Update
      attr_reader :product, :error, :errors

      def self.call(id:, params:)
        new(id: id, params: params).call
      end

      def initialize(id:, params:)
        @id = id
        @params = params || {}
        @product = nil
        @error = nil
        @errors = {}
      end

      def call
        ActiveRecord::Base.transaction do
          @product = Product.find_by(id: @id)
          unless @product
            @error = "Product not found"
            raise ActiveRecord::Rollback
          end

          unless @product.update(product_attributes)
            @errors = @product.errors.to_hash
            raise ActiveRecord::Rollback
          end

          assign_prices! if @params.key?(:prices)
          assign_health_goals! if @params.key?(:health_goal_ids)
        end

        self
      rescue StandardError => e
        @error ||= "Error updating product: #{e.message}"
        self
      end

      def success?
        @error.nil? && @product.present?
      end

      private

      def product_attributes
        @params.slice(:name, :description, :image_url, :image_path, :sku, :pv, :category_id, :active, :flavor, :disclaimer)
      end

      def assign_health_goals!
        ids = Array(@params[:health_goal_ids]).reject(&:blank?)
        @product.health_goal_ids = ids
      end

      def assign_prices!
        prices = @params[:prices]
        return unless prices.is_a?(Hash)

        prices.each do |level_key, price|
          level = find_level(level_key)
          next unless level

          product_price = @product.product_prices.find_or_initialize_by(level: level)

          if price.blank?
            product_price.destroy if product_price.persisted?
            next
          end

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

