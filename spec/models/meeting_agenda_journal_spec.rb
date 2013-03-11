require 'spec_helper'
require 'meeting_minutes'

describe MeetingAgendaJournal do
  include Meeting::PluginSpecHelper

  let(:journal) { Factory.build(:meeting_agenda_journal) }

  it_should_behave_like "customized journal class"
end
