FactoryGirl.define do
  factory :meeting do |m|
    m.sequence(:title) { |n| "Meeting #{n}" }
  end
end
