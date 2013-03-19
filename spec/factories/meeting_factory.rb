FactoryGirl.define do
  factory :meeting do |m|
    project
    m.sequence(:title) { |n| "Meeting #{n}" }
  end
end
