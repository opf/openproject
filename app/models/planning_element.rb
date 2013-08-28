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

  def append_scenario_dates_to_journal
    changes = {}
    alternate_dates.each do |d|
      if d.scenario.present? && (!(alternate_date_changes = d.changes).empty? || d.marked_for_destruction?)
        ["start_date", "due_date"].each do |field|
          old_value = if (scenario_changes = alternate_date_changes["scenario_id"])
            scenario_changes.first.nil? ? nil : d.send(field)
          else
            alternate_date_changes[field].nil? ? d.send(field) : alternate_date_changes[field].first
          end
          new_value = d.marked_for_destruction? ? nil : d.send(field)
          changes.merge!({ "scenario_#{d.scenario.id}_#{field}" => [old_value, new_value] }) unless new_value == old_value
        end
      end
    end
    journal_changes.append_changes!(changes)
  end

  before_save :append_scenario_dates_to_journal

  def duration
    if start_date >= due_date
      1
    else
      due_date - start_date + 1
    end
  end


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
