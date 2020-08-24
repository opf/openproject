#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module TimeEntries
  class BaseContract < ::ModelContract
    include AssignableValuesContract
    include AssignableCustomFieldValues

    delegate :work_package,
             :project,
             :available_custom_fields,
             :new_record?,
             to: :model

    def self.model
      TimeEntry
    end

    def validate
      validate_hours_are_in_range
      validate_project_is_set
      validate_work_package

      super
    end

    attribute :project_id
    attribute :work_package_id
    attribute :activity_id do
      validate_activity_active
    end
    attribute :hours
    attribute :comments
    attribute_alias :comments, :comment

    attribute :spent_on
    attribute :tyear
    attribute :tmonth
    attribute :tweek

    def assignable_activities
      if !model.project
        TimeEntryActivity.none
      else
        TimeEntryActivity::Scopes::ActiveInProject.fetch(model.project)
      end
    end

    # Necessary for custom fields
    # of type version.
    def assignable_versions
      work_package.try(:assignable_versions) || project.try(:assignable_versions) || []
    end

    private

    def validate_work_package
      return unless model.work_package || model.work_package_id_changed?

      if work_package_invisible? ||
         work_package_not_in_project?
        errors.add :work_package_id, :invalid
      end
    end

    def validate_hours_are_in_range
      errors.add :hours, :invalid if model.hours&.negative?
    end

    def validate_project_is_set
      errors.add :project_id, :invalid if model.project.nil?
    end

    def validate_activity_active
      errors.add :activity_id, :inclusion if model.activity_id && !assignable_activities.exists?(model.activity_id)
    end

    def work_package_invisible?
      model.work_package.nil? || !model.work_package.visible?(user)
    end

    def work_package_not_in_project?
      model.work_package && model.project != model.work_package.project
    end
  end
end
