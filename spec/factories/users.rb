FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "email.#{n}@example.com" }
    full_name { FFaker::Name.name }
    role 'user'

    trait :regular do
      role 'user'
    end

    trait :manager do
      role 'manager'
    end
  end
end
