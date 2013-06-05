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

FactoryGirl.define do
  factory :tracker do
    sequence(:position) { |p| p }
    name { |a| "Tracker No. #{a.position}" }
  end

  factory :tracker_bug, :class => Tracker do
    name "Bug"
    is_in_chlog true
    position 1

    # reuse existing tracker with the given name
    # this prevents a validation error (name has to be unique)
    initialize_with { Tracker.find_or_create_by_name(name)}

    factory :tracker_feature do
      name "Feature"
      position 2
    end

    factory :tracker_support do
      name "Support"
      position 3
    end

    factory :tracker_task do
      name "Task"
      position 4
    end
  end

  factory :tracker_with_workflow, :class => Tracker do
    is_in_chlog true
    sequence(:name) { |n| "Tracker #{n}" }
    sequence(:position) { |n| n }
    after :build do |t|
      t.workflows = [FactoryGirl.build(:workflow_with_default_status)]
    end
  end
end
