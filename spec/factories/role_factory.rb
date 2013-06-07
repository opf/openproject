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
  factory :role do
    permissions []
    sequence(:name) { |n| "role_#{n}"}
    assignable true

    factory :non_member do
      name "Non member"
      builtin Role::BUILTIN_NON_MEMBER
      assignable false
    end

    factory :anonymous_role do
      name "Anonymous"
      builtin Role::BUILTIN_ANONYMOUS
      assignable false
    end
  end
end

