FactoryGirl.define do
  factory :meeting_participant do |mp|
    user
    meeting
  end
end
