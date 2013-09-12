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
  factory :custom_value do
    custom_field
    value ""

    factory :principal_custom_value do
      custom_field :factory => :user_custom_field
      customized :factory => :user
    end

    factory :issue_custom_value do
      custom_field :factory => :issue_custom_field
      customized :factory => :work_package
    end

    factory :work_package_custom_value do
      custom_field :factory => :issue_custom_field
      customized :factory => :work_package
    end
  end
end
