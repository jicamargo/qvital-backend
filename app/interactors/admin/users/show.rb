module Admin
  module Users
    class Show
      attr_reader :user, :error

      def self.call(id:)
        new(id: id).call
      end

      def initialize(id:)
        @id = id
        @user = nil
        @error = nil
      end

      def call
        @user = User.includes(:level).find_by(id: @id)
        @error = "User not found" unless @user
        self
      rescue StandardError => e
        @error = "Error loading user: #{e.message}"
        self
      end

      def success?
        @error.nil?
      end
    end
  end
end
