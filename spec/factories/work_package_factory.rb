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
  factory :work_package, :class => 'WorkPackageData' do
    priority
    project :factory => :project_with_trackers
    sequence(:subject) { |n| "Issue No. #{n}" }
    description { |i| "Description for '#{i.subject}'" }
    author :factory => :user
  end
end
