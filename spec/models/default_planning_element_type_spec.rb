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
#
# require File.expand_path('../../spec_helper', __FILE__)
#
# describe DefaultPlanningElementType do
#   describe '- Relations ' do
#     it 'can read the project_type w/ the help of the belongs_to association' do
#       project_type                  = FactoryGirl.create(:project_type)
#       default_planning_element_type = FactoryGirl.create(:default_planning_element_type,
#                                                      :project_type_id => project_type.id)
#
#       default_planning_element_type.reload
#
#       default_planning_element_type.project_type.should == project_type
#     end
#
#     it 'can read the planning_element_type w/ the help of the belongs_to association' do
#       planning_element_type         = FactoryGirl.create(:planning_element_type)
#       default_planning_element_type = FactoryGirl.create(:default_planning_element_type,
#                                                      :planning_element_type_id => planning_element_type.id)
#
#       default_planning_element_type.reload
#
#       default_planning_element_type.planning_element_type.should == planning_element_type
#     end
#   end
# end
