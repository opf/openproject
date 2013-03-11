require 'meeting_agenda'

FactoryGirl.define do
  factory :meeting_agenda_journal do |m|
    m.association :journaled, :factory => :meeting_agenda
  end
end
