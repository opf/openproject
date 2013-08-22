#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2011-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'
require 'meeting_minutes'

describe MeetingMinutesJournal do
  include PluginSpecHelper

  let(:journal) { FactoryGirl.build(:meeting_minutes_journal) }

  it_should_behave_like "customized journal class"
end
