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

require File.expand_path('../../spec_helper', __FILE__)

describe PlanningElementStatus do
  describe '- Relations ' do
    describe '#planning_elements' do
      it 'can read planning_elements w/ the help of the has_many association' do
        planning_element_status = FactoryGirl.create(:planning_element_status)
        planning_element        = FactoryGirl.create(:planning_element,
                                                 :planning_element_status_id => planning_element_status.id)

        planning_element_status.reload

        planning_element_status.planning_elements.size.should == 1
        planning_element_status.planning_elements.first.should == planning_element
      end
    end
  end
end
