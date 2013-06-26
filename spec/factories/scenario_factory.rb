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
  factory(:scenario, :class => Scenario) do
    sequence(:name) { |n| "Scenario No. #{n}" }
    sequence(:description) { |n| "Scenario No. #{n} would allow us to launch last week." }

    association :project
  end
end
