require 'meeting_minutes'

Factory.define :meeting_minutes_journal do |m|
  m.association :journaled, :factory => :meeting_minutes
end
