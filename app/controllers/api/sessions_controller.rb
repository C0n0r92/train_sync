module Api
  class SessionsController < ApiController
    before_action :require_device_token!, only: [:current, :results]
    before_action :find_session, only: [:show, :results]

    def create
      qr_code = QrCode.find_by(short_id: params[:qr_code_short_id])

      return render json: { error: 'QR code not found' }, status: :not_found unless qr_code
      return render json: { error: 'QR code has expired' }, status: :unprocessable_entity if qr_code.expired?
      return render json: { error: 'Device token required' }, status: :unprocessable_entity unless params[:device_token]

      athlete = User.find(params[:athlete_id]) if params[:athlete_id]
      device_token_obj = register_or_update_device_token(athlete)

      qr_scan = qr_code.qr_scans.build(athlete_id: device_token_obj.user_id, scanned_at: Time.current)

      unless qr_scan.save
        return render json: { error: 'Failed to record scan', details: qr_scan.errors }, status: :unprocessable_entity
      end

      workout_session = WorkoutSession.create!(
        qr_scan_id: qr_scan.id,
        athlete_id: device_token_obj.user_id,
        workout_id: qr_code.workout_id,
        started_at: Time.current
      )

      render json: session_json(workout_session, device_token_obj), status: :created
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: 'Invalid athlete ID' }, status: :unprocessable_entity
    end

    def current
      user = authenticate_device_token
      return render json: { error: 'Unauthorized' }, status: :unauthorized unless user

      session = user.workout_sessions.where(completed_at: nil).order(created_at: :desc).first

      if session
        render json: session_json(session), status: :ok
      else
        render json: { workout: nil }, status: :ok
      end
    end

    def show
      render json: session_json(@session), status: :ok
    end

    def results
      block_results = params.require(:block_results)
      return render json: { error: 'Invalid block results' }, status: :unprocessable_entity unless block_results.is_a?(Array)

      if @session.update(completed_at: Time.current)
        workout_result = WorkoutResult.create!(
          workout_session_id: @session.id,
          block_results: block_results,
          completed_at: Time.current
        )

        render json: {
          session: session_json(@session),
          result: result_json(workout_result)
        }, status: :created
      else
        render json: { error: 'Failed to submit results', details: @session.errors }, status: :unprocessable_entity
      end
    end

    private

    def find_session
      @session = WorkoutSession.find(params[:id])
    end

    def register_or_update_device_token(athlete = nil)
      device_token_string = params[:device_token]

      existing_token = DeviceToken.find_by(token: device_token_string)
      return existing_token if existing_token

      athlete ||= User.create!(
        email: "device_#{SecureRandom.hex(8)}@scanrx.local",
        password: SecureRandom.hex(32),
        password_confirmation: SecureRandom.hex(32),
        role: :athlete
      )

      DeviceToken.create!(
        user_id: athlete.id,
        token: device_token_string,
        platform: :connect_iq,
        expires_at: 90.days.from_now
      )
    end

    def session_json(session, device_token = nil)
      result = {
        id: session.id,
        athlete_id: session.athlete_id,
        workout_id: session.workout_id,
        workout: session.workout ? workout_json(session.workout) : nil,
        started_at: session.started_at,
        completed_at: session.completed_at,
        created_at: session.created_at
      }

      result[:device_token] = device_token.token if device_token
      result
    end

    def workout_json(workout)
      {
        id: workout.id,
        name: workout.name,
        blocks: workout.blocks
      }
    end

    def result_json(result)
      {
        id: result.id,
        workout_session_id: result.workout_session_id,
        block_results: result.block_results,
        completed_at: result.completed_at
      }
    end
  end
end
