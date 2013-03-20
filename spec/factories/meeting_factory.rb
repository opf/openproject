FactoryGirl.define do
  factory :meeting do |m|
    author :factory => :user
    project
    m.sequence(:title) { |n| "Meeting #{n}" }
  end
end
