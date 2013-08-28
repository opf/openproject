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

  validates_presence_of :subject, :project

  validates_length_of :subject, :maximum => 255, :unless => lambda { |e| e.subject.blank? }

  validate do
    if self.due_date and self.start_date and self.due_date < self.start_date
      errors.add :due_date, :greater_than_start_date
    end

    if self.is_milestone?
      if self.due_date and self.start_date and self.start_date != self.due_date
        errors.add :due_date, :not_start_date
      end
    end

    # TODO: reconsider self.parent.is_a?(PlanningElement)
    #       once any of the errors can also apply when using issues
    if self.parent && self.parent.is_a?(PlanningElement)
      errors.add :parent, :cannot_be_milestone if parent.is_milestone?
      errors.add :parent, :cannot_be_in_another_project if parent.project != project
      errors.add :parent, :cannot_be_in_recycle_bin if parent.deleted?
    end

  end
end
