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

require 'spec_helper'

describe "Models acting as list (acts_as_list)" do
  it "should include the patch" do
    ActiveRecord::Acts::List::InstanceMethods.included_modules.should include(OpenProject::Patches::ActsAsList)
  end

  describe :move_to= do
    let(:includer) do
      class ActsAsListPatchIncluder
        include OpenProject::Patches::ActsAsList
      end

      ActsAsListPatchIncluder.new
    end

    it "should move to top when wanting to move highest" do
      includer.should_receive :move_to_top

      includer.move_to = "highest"
    end

    it "should move to bottom when wanting to move lowest" do
      includer.should_receive :move_to_bottom

      includer.move_to = "lowest"
    end

    it "should move higher when wanting to move higher" do
      includer.should_receive :move_higher

      includer.move_to = "higher"
    end

    it "should move lower when wanting to move lower" do
      includer.should_receive :move_lower

      includer.move_to = "lower"
    end
  end
end
