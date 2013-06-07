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
  factory :query do
    project
    user :factory => :user
    sequence(:name) { |n| "Query {n}" }

    factory :public_query do
      is_public true
      sequence(:name) { |n| "Public query {n}" }
    end

    factory :private_query do
      is_public false
      sequence(:name) { |n| "Private query {n}" }
    end
  end
end
