class QrCode < ApplicationRecord

  belongs_to :workout
  has_many :qr_scans, class_name: "QrScan", dependent: :destroy

  enum :variant, { public: 0, squad: 1, single_use: 2 }, prefix: true

  validates :short_id, presence: true, uniqueness: true
  validates :workout_id, presence: true
  validates :variant, presence: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def expired?
    expires_at && expires_at <= Time.current
  end
end
