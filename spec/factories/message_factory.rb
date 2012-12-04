FactoryGirl.define do
  factory :message do
    board
    sequence(:content) { |n| "Message content {n}" }
    sequence(:subject) { |n| "Message subject {n}" }
  end
end
