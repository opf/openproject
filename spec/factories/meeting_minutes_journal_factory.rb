require 'meeting_minutes'

FactoryGirl.define do
  factory :meeting_minutes_journal do |m|
    m.association :journaled, :factory => :meeting_minutes
  end
end
