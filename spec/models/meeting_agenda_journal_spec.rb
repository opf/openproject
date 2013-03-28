require File.dirname(__FILE__) + '/../spec_helper'
require 'meeting_minutes'

describe MeetingAgendaJournal do
  include PluginSpecHelper

  let(:journal) { FactoryGirl.build(:meeting_agenda_journal) }

  it_should_behave_like "customized journal class"
end
