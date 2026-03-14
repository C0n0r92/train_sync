class WorkoutResult < ApplicationRecord
  belongs_to :workout_session

  validates :workout_session_id, presence: true
  validates :block_results, presence: true

  def self.from_device(session_id, block_results)
    create!(
      workout_session_id: session_id,
      block_results: block_results,
      completed_at: Time.current
    )
  end
end
