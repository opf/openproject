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

class PlanningElementScenario
  unloadable

  attr_accessor :alternate_date

  def initialize(alternate_date)
    raise ArgumentError, 'Please pass an actual alternate date' if alternate_date.nil?

    @alternate_date = alternate_date
  end

  delegate :start_date, :start_date=, :due_date, :due_date=,
           :scenario, :scenario_id,
           :duration, :planning_element,
           :valid?, :errors,
           :to => :alternate_date

  delegate :name, :id, :to_param, :to => :scenario

  def _destroy
    false
  end

  def ==(other)
    other.is_a?(self.class) &&
      other.alternate_date == @alternate_date
  end

  def eql?(other)
    other.class == self.class &&
      other.alternate_date == @alternate_date
  end

  def hash
    @alternate_date.hash
  end
end
