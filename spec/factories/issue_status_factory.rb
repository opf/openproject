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
  factory :issue_status do
    sequence(:name) { |n| "status #{n}" }
    is_closed false

    factory :closed_issue_status do
      is_closed true
    end

    factory :default_issue_status do
      is_default true
    end

  end
end
