module Api
  class CoachesController < ApiController
    before_action :require_user!
    before_action :find_coach
    before_action :authorize_access!

    def dashboard
      workouts = @coach.workouts.order(created_at: :desc)

      analytics = workouts.map do |workout|
        {
          id: workout.id,
          name: workout.name,
          status: workout.status,
          scan_count: workout.qr_scans.count,
          started_count: workout.workout_sessions.count,
          completed_count: workout.workout_sessions.where.not(completed_at: nil).count,
          last_scan_at: workout.qr_scans.maximum(:scanned_at),
          last_completion_at: workout.workout_sessions.maximum(:completed_at),
          created_at: workout.created_at,
          updated_at: workout.updated_at
        }
      end

      render json: {
        coach: coach_json(@coach),
        workouts: analytics,
        summary: {
          total_workouts: workouts.count,
          published_count: workouts.where(status: :published).count,
          draft_count: workouts.where(status: :draft).count,
          total_scans: WorkoutSession.joins(:workout).where(workouts: { coach_id: @coach.id }).count,
          total_completions: WorkoutSession.joins(:workout).where(workouts: { coach_id: @coach.id }).where.not(completed_at: nil).count
        }
      }, status: :ok
    end

    private

    def find_coach
      @coach = User.find(params[:id])
    end

    def authorize_access!
      return if current_user.id == @coach.id
      return if current_user.role_admin?

      render json: { error: 'Unauthorized' }, status: :forbidden
    end

    def coach_json(coach)
      {
        id: coach.id,
        email: coach.email,
        role: coach.role
      }
    end
  end
end
