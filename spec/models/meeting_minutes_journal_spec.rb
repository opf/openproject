require File.dirname(__FILE__) + '/../spec_helper'
require 'meeting_minutes'

describe MeetingMinutesJournal do
  include PluginSpecHelper

  let(:journal) { FactoryGirl.build(:meeting_minutes_journal) }

  it_should_behave_like "customized journal class"
end
