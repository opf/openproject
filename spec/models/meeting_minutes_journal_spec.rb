require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../plugin_spec_helper'

require 'meeting_minutes'

describe MeetingMinutesJournal do
  include Meeting::PluginSpecHelper

  let(:journal) { Factory.build(:meeting_minutes_journal) }

  it_should_behave_like "customized journal class"
end
