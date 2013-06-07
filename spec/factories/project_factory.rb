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
  factory :project do
    sequence(:name) { |n| "My Project No. #{n}" }
    sequence(:identifier) { |n| "myproject_no_#{n}" }
    enabled_module_names Redmine::AccessControl.available_project_modules

    factory :public_project do
      is_public true
    end

    factory :project_with_trackers do
      after :build do |project|
        project.trackers << FactoryGirl.build(:tracker)
      end
      after :create do |project|
        project.trackers.each { |tracker| tracker.save! }
      end

      factory :valid_project do
        after :build do |project|
          project.trackers << FactoryGirl.build(:tracker_with_workflow)
        end
      end
    end
  end
end
