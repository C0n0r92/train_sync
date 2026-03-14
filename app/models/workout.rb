class Workout < ApplicationRecord
  belongs_to :coach, class_name: "User"
  has_many :qr_codes, class_name: "QrCode", dependent: :destroy
  has_many :workout_sessions, dependent: :destroy
  has_many :qr_scans, through: :qr_codes, class_name: "QrScan"

  enum :status, { draft: 0, published: 1 }, prefix: true

  validates :name, presence: true
  validates :coach_id, presence: true
  validates :status, presence: true
end
