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

class AlternateDate < ActiveRecord::Base
  unloadable

  self.table_name = 'alternate_dates'

  belongs_to :planning_element, :class_name  => "PlanningElement",
                                :foreign_key => 'planning_element_id'
  belongs_to :scenario,         :class_name  => "Scenario",
                                :foreign_key => 'scenario_id'

  # history-related  = historic
  scope :historic, :conditions => "#{self.table_name}.scenario_id IS NULL"

  # scenario-related = scenaric
  scope :scenaric, :conditions => "#{self.table_name}.scenario_id IS NOT NULL"

  validates_presence_of :start_date, :due_date, :planning_element

  delegate :planning_element_type, :planning_element_type_id, :is_milestone?, :to => :planning_element

  attr_accessible :start_date, :due_date

  validate do
    if self.due_date and self.start_date and self.due_date < self.start_date
      errors.add :due_date, :greater_than_start_date
    end

    if self.planning_element.present? and self.is_milestone?
      if self.due_date and self.start_date and self.start_date != self.due_date
        errors.add :due_date, :not_start_date
      end
    end
  end

  def duration
    if start_date >= due_date
      1
    else
      due_date - start_date + 1
    end
  end

end
