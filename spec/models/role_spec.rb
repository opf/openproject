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

describe Role do
  describe '#by_permission' do
    it "returns roles with given permission" do
      edit_project_role = FactoryGirl.create :role, :permissions => [:edit_project]
          
      expect( Role.by_permission(:edit_project) ).to     include edit_project_role
      expect( Role.by_permission(:some_other)   ).to_not include edit_project_role
    end
  end
end
