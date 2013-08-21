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
  factory :work_package_custom_field do
    sequence(:name) {|n| "Custom Field Nr. #{n}"}
    regexp ""
    is_required false
    min_length false
    default_value ""
    max_length false
    editable true
    possible_values ""
    visible true
    field_format "bool"
    type "WorkPackageCustomField"
  end
end
