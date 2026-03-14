FactoryBot.define do
  factory :qr_code do
    workout { association :workout, :published }
    short_id { SecureRandom.hex(8) }
    variant { :public }
    expires_at { nil }

    trait :single_use do
      variant { :single_use }
      expires_at { 7.days.from_now }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
