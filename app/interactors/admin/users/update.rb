module Admin
  module Users
    class Update
      attr_reader :user, :error, :errors

      def self.call(id:, params:)
        new(id: id, params: params).call
      end

      def initialize(id:, params:)
        @id = id
        @params = params || {}
        @user = nil
        @error = nil
        @errors = {}
      end

      def call
        @user = User.find_by(id: @id)
        unless @user
          @error = "User not found"
          return self
        end

        unless @user.update(user_attributes)
          @errors = @user.errors.to_hash
        end

        self
      rescue StandardError => e
        @error = "Error updating user: #{e.message}"
        self
      end

      def success?
        @error.nil? && @errors.empty?
      end

      private

      def user_attributes
        @params.slice(:name, :last_name, :phone, :role, :level_id, :premium_active, :premium_expires_at)
      end
    end
  end
end
