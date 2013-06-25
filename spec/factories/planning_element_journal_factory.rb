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

PlanningElement # this should fix "uninitialized constant PlanningElementJournal" errors on ci.

FactoryGirl.define do
  factory(:planning_element_journal, :class => WorkPackageJournal) do

    association :journaled, :factory => :planning_element
  end
end
