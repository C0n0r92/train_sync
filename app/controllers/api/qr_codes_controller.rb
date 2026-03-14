module Api
  class QrCodesController < ApiController
    skip_before_action :require_user!

    def resolve
      qr_code = QrCode.find_by(short_id: params[:short_id])

      return render json: { error: 'QR code not found' }, status: :not_found unless qr_code
      return render json: { error: 'QR code has expired' }, status: :unprocessable_entity if qr_code.expired?

      render json: {
        qr_code: qr_json(qr_code),
        workout: workout_json(qr_code.workout)
      }, status: :ok
    end

    private

    def qr_json(qr_code)
      {
        id: qr_code.id,
        short_id: qr_code.short_id,
        variant: qr_code.variant,
        workout_id: qr_code.workout_id,
        expires_at: qr_code.expires_at,
        created_at: qr_code.created_at
      }
    end

    def workout_json(workout)
      {
        id: workout.id,
        name: workout.name,
        blocks: workout.blocks,
        coach_id: workout.coach_id
      }
    end
  end
end
