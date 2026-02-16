module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last

    unless token
      render json: { error: 'No token' }, status: :unauthorized and return
    end

    result = Auth::SyncUser.call(token: token)

    unless result.success?
      render json: { error: result.error || 'Unauthorized' }, status: :unauthorized and return
    end

    @current_user = result.user
  end

  def current_user
    @current_user
  end
end
