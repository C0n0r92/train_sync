FactoryBot.define do
  factory :qr_scan do
    qr_code { association :qr_code }
    athlete { association :user, role: :athlete }
    scanned_at { Time.current }
  end
end
