#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe "MeetingMinutes" do
  before do
    @min = FactoryGirl.build :meeting_minutes
  end

  # meeting minutes are editable when the meeting agenda is locked
  describe "#editable?" do
    before(:each) do
      @mee = FactoryGirl.build :meeting
      @min.meeting = @mee
    end
    describe "with no agenda present" do
      it "is not editable" do
        @min.editable?.should be_false
      end
    end
    describe "with an agenda present" do
      before(:each) do
        @a = FactoryGirl.build :meeting_agenda
        @mee.agenda = @a
      end
      it "is not editable when the agenda is open" do
        @min.editable?.should be_false
      end
      it "is editable when the agenda is closed" do
        @a.lock!
        @min.editable?.should be_true
      end
    end
  end
end
