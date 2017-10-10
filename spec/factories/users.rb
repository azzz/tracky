FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "email.#{n}@example.com" }
    full_name { FFaker::Name.name }
    password 'password'
    password_confirmation 'password'
    role 'client'

    trait :client do
      role 'client'
    end

    trait :manager do
      role 'manager'
    end
  end
end
