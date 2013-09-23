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

describe "MeetingAgenda" do
  before(:each) do
    @a = FactoryGirl.build :meeting_agenda, :text => "Some content...\n\nMore content!\n\nExtraordinary content!!"
  end

  # TODO: Test the right user and messages are set in the history
  describe "#lock!" do
    it "locks the agenda" do
      @a.save
      @a.reload
      @a.lock!
      @a.reload
      @a.locked.should be_true
    end
  end

  describe "#unlock!" do
    it "unlocks the agenda" do
      @a.locked = true
      @a.save
      @a.reload
      @a.unlock!
      @a.reload
      @a.locked.should be_false
    end
  end

  # a meeting agenda is editable when it is not locked
  describe "#editable?" do
    it "is editable when not locked" do
      @a.locked = false
      @a.editable?.should be_true
    end
    it "is not editable when locked" do
      @a.locked = true
      @a.editable?.should be_false
    end
  end
end
