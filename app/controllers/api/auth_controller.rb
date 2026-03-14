module Api
  class AuthController < ApiController
    def signup
      user = User.new(signup_params)

      if user.save
        token = generate_token(user)
        render json: {
          user: user_json(user),
          token: token
        }, status: :created
      else
        error_details = user.errors.messages.map { |field, msgs| "#{field}: #{msgs.join(', ')}" }.join("; ")
        render json: { error: error_details, details: user.errors.messages }, status: :unprocessable_entity
      end
end

    def login
      user = User.find_by(email: params[:email])

      if user&.valid_password?(params[:password])
        token = generate_token(user)
        render json: {
          user: user_json(user),
          token: token
        }, status: :ok
      else
        render json: { error: 'Invalid email or password' }, status: :unauthorized
      end
    end

    def logout
      require_user!
      # Token is stateless, client just discards it
      render json: { message: 'Logged out' }, status: :ok
    end

    def refresh
      require_user!
      token = generate_token(current_user)
      render json: { token: token }, status: :ok
    end

    private

    def signup_params
      params.require(:user).permit(:email, :password, :password_confirmation, :role)
    end

    def generate_token(user)
      payload = {
        user_id: user.id,
        email: user.email,
        role: user.role,
        iat: Time.current.to_i,
        exp: (Time.current + 24.hours).to_i
      }
      JWT.encode(payload, jwt_secret, 'HS256')
    end

    def jwt_secret
      Rails.application.config.secret_key_base
    end

    def user_json(user)
      {
        id: user.id,
        email: user.email,
        role: user.role
      }
    end
  end
end
