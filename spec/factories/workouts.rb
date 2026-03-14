FactoryBot.define do
  factory :workout do
    coach { association :user, role: :coach }
    name { Faker::Hacker.say_something_smart }
    blocks do
      [
        { type: 'run', target_distance_km: 5 },
        { type: 'rest', duration_seconds: 120 }
      ]
    end
    status { :draft }
    version { 1 }
    is_public { false }

    trait :published do
      status { :published }
    end
  end
end
