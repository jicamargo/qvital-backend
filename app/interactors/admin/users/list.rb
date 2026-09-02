module Admin
  module Users
    class List
      attr_reader :users, :error

      def self.call(params: {})
        new(params: params).call
      end

      def initialize(params: {})
        @params = params || {}
        @users = []
        @error = nil
      end

      def call
        scope = ::User.includes(:level).order(created_at: :desc)
        scope = scope.where(role: @params[:role]) if @params[:role].present?

        scope = scope.search_by_text(@params[:search]) if @params[:search].present?

        @users = scope
        self
      rescue StandardError => e
        Rails.logger.error "Error listing users (admin): #{e.message}"
        failure('Error inesperado cargando los usuarios')
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
