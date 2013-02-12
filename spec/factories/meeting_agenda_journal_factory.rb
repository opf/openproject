require 'meeting_agenda'

Factory.define :meeting_agenda_journal do |m|
  m.association :journaled, :factory => :meeting_agenda
end
