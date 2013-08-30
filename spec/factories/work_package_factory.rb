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
  factory :work_package do
    priority
    project :factory => :project_with_types
    status :factory => :issue_status
    sequence(:subject) { |n| "WorkPackage No. #{n}" }
    description { |i| "Description for '#{i.subject}'" }
    author :factory => :user

    after :build do |work_package|
      work_package.type = work_package.project.types.first unless work_package.type
    end

  end


end
