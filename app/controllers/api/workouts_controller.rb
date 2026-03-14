module Api
  class WorkoutsController < ApiController
    before_action :require_user!
    before_action :find_workout, only: [:show, :update, :publish, :qr]
    before_action :authorize_coach!, only: [:create, :update, :publish, :qr]
    before_action :authorize_owner!, only: [:update, :publish, :qr]

    def create
      workout = current_user.workouts.build(workout_params)

      if workout.save
        render json: workout_json(workout), status: :created
      else
        render json: { error: 'Failed to create workout', details: workout.errors }, status: :unprocessable_entity
      end
    end

    def show
      if @workout.status_draft? && @workout.coach_id != current_user.id
        render json: { error: 'Unauthorized' }, status: :forbidden
        return
      end

      render json: workout_json(@workout), status: :ok
    end

    def update
      return render json: { error: 'Cannot update published workout' }, status: :unprocessable_entity if @workout.status_published?

      if @workout.update(workout_params)
        @workout.increment!(:version)
        render json: workout_json(@workout), status: :ok
      else
        render json: { error: 'Failed to update workout', details: @workout.errors }, status: :unprocessable_entity
      end
    end

    def publish
      return render json: { error: 'Already published' }, status: :unprocessable_entity if @workout.status_published?
      return render json: { error: 'Cannot publish empty workout' }, status: :unprocessable_entity if @workout.blocks.blank?

      if @workout.update(status: :published)
        render json: workout_json(@workout), status: :ok
      else
        render json: { error: 'Failed to publish', details: @workout.errors }, status: :unprocessable_entity
      end
    end

    def qr
      return render json: { error: 'Must publish before generating QR' }, status: :unprocessable_entity unless @workout.status_published?

      qr_code = @workout.qr_codes.build(qr_params)

      if qr_code.save
        render json: qr_json(qr_code), status: :created
      else
        render json: { error: 'Failed to generate QR', details: qr_code.errors }, status: :unprocessable_entity
      end
    end

    private

    def find_workout
      @workout = Workout.find(params[:id])
    end

    def authorize_coach!
      unless current_user.role_coach?
        render json: { error: 'Only coaches can perform this action' }, status: :forbidden
        return
      end
    end

    def authorize_owner!
      unless @workout.coach_id == current_user.id
        render json: { error: 'Unauthorized' }, status: :forbidden
        return
      end
    end

    def authorize_show!
      if @workout.status_draft?
        unless @workout.coach_id == current_user.id
          render json: { error: 'Unauthorized' }, status: :forbidden
          return
        end
      end
    end

    def workout_params
      permitted = params.require(:workout).permit(:name, :is_public, blocks: [])
      # Ensure blocks is an array, not a single empty string
      permitted[:blocks] = [] if permitted[:blocks].blank? || permitted[:blocks] == ['']
      permitted
    end

    def qr_params
      defaults = { variant: :public, short_id: SecureRandom.hex(8) }
      params.require(:qr_code).permit(:variant, :expires_at).merge(defaults)
    end

    def workout_json(workout)
      {
        id: workout.id,
        coach_id: workout.coach_id,
        name: workout.name,
        blocks: workout.blocks,
        status: workout.status,
        version: workout.version,
        is_public: workout.is_public,
        created_at: workout.created_at,
        updated_at: workout.updated_at
      }
    end

    def qr_json(qr_code)
      {
        id: qr_code.id,
        short_id: qr_code.short_id,
        variant: qr_code.variant,
        url: qr_url(qr_code),
        expires_at: qr_code.expires_at,
        created_at: qr_code.created_at
      }
    end

    def qr_url(qr_code)
      "#{request.protocol}#{request.host}:#{request.port}/qr/#{qr_code.short_id}"
    end
  end
end
