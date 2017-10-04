FactoryGirl.define do
  factory :issue do
    association(:author, factory: :user)
    association(:assignee, factory: :user)
    title { FFaker::Lorem.sentence }
    description { FFaker::Lorem.paragraph }
    status 'pending'

    trait :resolved do
      status 'resolved'
    end

    trait :in_progress do
      status 'in_progress'
    end
  end
end
