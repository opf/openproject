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
  factory :board do
    project
    sequence(:name) { |n| "Board No. #{n}" }
    sequence(:description) { |n| "I am the Board No. #{n}" }
  end
end

