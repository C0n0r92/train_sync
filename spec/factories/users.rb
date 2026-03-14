FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'SecurePassword123!' }
    password_confirmation { 'SecurePassword123!' }
    role { :athlete }

    trait :coach do
      role { :coach }
    end

    trait :admin do
      role { :admin }
    end
  end
end
