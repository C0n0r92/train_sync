class WorkoutSession < ApplicationRecord
  belongs_to :qr_scan, class_name: "QrScan"
  belongs_to :athlete, class_name: "User", foreign_key: :athlete_id
  belongs_to :workout

  has_one :workout_result, dependent: :destroy

  validates :qr_scan_id, presence: true
  validates :athlete_id, presence: true
  validates :workout_id, presence: true

  scope :completed, -> { where("completed_at IS NOT NULL") }
  scope :in_progress, -> { where("started_at IS NOT NULL AND completed_at IS NULL") }
  scope :pending, -> { where("started_at IS NULL") }

  def completed?
    completed_at.present?
  end

  def in_progress?
    started_at.present? && !completed?
  end
end
