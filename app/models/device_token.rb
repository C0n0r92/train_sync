class DeviceToken < ApplicationRecord
  belongs_to :user

  enum :platform, { connect_iq: 0, apple_watch: 1 }, prefix: true

  validates :token, presence: true, uniqueness: true
  validates :user_id, presence: true
  validates :platform, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def active?
    !expired?
  end

  def self.generate_token
    SecureRandom.hex(32)
  end
end
