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

class PlanningElementStatus < Enumeration
  unloadable

  has_many :planning_elements, :class_name  => "PlanningElement",
                               :foreign_key => 'planning_element_status_id'

  OptionName = :enumeration_planning_element_statuses

  def option_name
    OptionName
  end

  def objects_count
    planning_elements.count
  end

  def transfer_relations(to)
    planning_elements.update_all(:planning_element_status_id => to.id)
  end
end
