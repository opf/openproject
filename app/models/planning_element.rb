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

class PlanningElement < WorkPackage
  unloadable

  include ActiveModel::ForbiddenAttributesProtection

  accepts_nested_attributes_for_apis_for :parent,
                                         :planning_element_status,
                                         :type,
                                         :project

  scope :for_projects, lambda { |projects|
    {:conditions => {:project_id => projects}}
  }
  
end
