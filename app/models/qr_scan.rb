class QrScan < ApplicationRecord
  belongs_to :qr_code, class_name: "QrCode"
  belongs_to :athlete, class_name: "User", foreign_key: :athlete_id

  validates :qr_code_id, presence: true
  validates :athlete_id, presence: true
  validates :scanned_at, presence: true

  before_validation :set_scanned_at, on: :create

  private

  def set_scanned_at
    self.scanned_at = Time.current if scanned_at.blank?
  end
end
