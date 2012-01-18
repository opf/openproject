#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../test_helper', __FILE__)

class TrackerDropTest < ActiveSupport::TestCase
  def setup
    @tracker = Tracker.generate!
    @drop = @tracker.to_liquid
  end

  context "drop" do
    should "be a TrackerDrop" do
      assert @drop.is_a?(TrackerDrop), "drop is not a TrackerDrop"
    end
  end

  context "#name" do
    should "return the name" do
      assert_equal @tracker.name, @drop.name
    end
  end
end
