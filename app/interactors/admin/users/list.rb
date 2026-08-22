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

        if @params[:search].present?
          term = "%#{@params[:search].strip}%"
          scope = scope.where("email ILIKE :term OR name ILIKE :term OR last_name ILIKE :term", term: term)
        end

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
