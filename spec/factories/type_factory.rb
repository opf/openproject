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
  factory :type do
    sequence(:position) { |p| p }
    name { |a| "Type No. #{a.position}" }
  end

  factory :type_bug, :class => Type do
    name "Bug"
    is_in_chlog true
    position 1

    # reuse existing type with the given name
    # this prevents a validation error (name has to be unique)
    initialize_with { Type.find_or_create_by_name(name)}

    factory :type_feature do
      name "Feature"
      position 2
      is_default true
    end

    factory :type_support do
      name "Support"
      position 3
    end

    factory :type_task do
      name "Task"
      position 4
    end
  end

  factory :type_with_workflow, :class => Type do
    is_in_chlog true
    sequence(:name) { |n| "Type #{n}" }
    sequence(:position) { |n| n }
    after :build do |t|
      t.workflows = [FactoryGirl.build(:workflow_with_default_status)]
    end
  end
end
