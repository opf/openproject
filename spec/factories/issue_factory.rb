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
  factory :issue do
    priority
    project :factory => :project_with_trackers
    status :factory => :issue_status
    sequence(:subject) { |n| "Issue No. #{n}" }
    description { |i| "Description for '#{i.subject}'" }
    author :factory => :user

    after :build do |issue|
      # a valid issue needs a tracker which is known to its project
      issue.tracker = issue.project.trackers.first unless issue.tracker
    end
  end
end
