class ApiController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  protected

  def current_user
    @current_user ||= authenticate_token
  end

  def authenticate_token
    token = request.headers['Authorization']&.split(' ')&.last
    return nil unless token

    begin
      payload = JWT.decode(token, jwt_secret, true, algorithm: 'HS256')[0]
      User.find(payload['user_id'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      nil
    end
  end

  def jwt_secret
    Rails.application.config.secret_key_base
  end

  def authenticate_device_token
    token = request.headers['X-Device-Token']
    return nil unless token

    device_token = DeviceToken.find_by(token: token)
    return nil unless device_token&.active?

    device_token.user
  end

  def require_user!
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
  end

  def require_device_token!
    render json: { error: 'Unauthorized' }, status: :unauthorized unless authenticate_device_token
  end

  def not_found
    render json: { error: 'Not Found' }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { error: exception.message, details: exception.record.errors }, status: :unprocessable_entity
  end
end
