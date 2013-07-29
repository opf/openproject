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
  factory(:planning_element_type, :class => Type) do
    sequence(:name) { |n| "Planning Element Type No. #{n}" }

    in_aggregation true
    is_milestone false
    is_default false

    sequence(:position) { |n| n }
  end
end

FactoryGirl.define do
  factory(:planning_element_type_milestone,
          :parent => :planning_element_type) do
    is_milestone true
  end
end
