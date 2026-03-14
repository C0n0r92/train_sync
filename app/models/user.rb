class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { athlete: 0, coach: 1, admin: 2 }, prefix: true

  has_many :workouts, foreign_key: :coach_id, dependent: :destroy
  has_many :device_tokens, dependent: :destroy
  has_many :qr_scans, class_name: "QrScan", dependent: :destroy
  has_many :workout_sessions, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :role, presence: true

  def coach?
    role == 'coach'
  end

  def athlete?
    role == 'athlete'
  end
end
