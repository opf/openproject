require 'spec_helper'
require 'meeting_minutes'

describe MeetingMinutesJournal do
  include Meeting::PluginSpecHelper

  let(:journal) { FactoryGirl.build(:meeting_minutes_journal) }

  it_should_behave_like "customized journal class"
end
