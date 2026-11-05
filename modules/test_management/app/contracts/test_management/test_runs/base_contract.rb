# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module TestManagement
  module TestRuns
    class BaseContract < ::ModelContract
      def self.model
        TestManagement::TestRun
      end

      attribute :project
      attribute :name
      attribute :description
      attribute :assigned_to
      attribute :assigned_to_id
      attribute :author
      attribute :start_date
      attribute :end_date
      attribute :selection_mode
      attribute :filter_options
      attribute :selected_case_ids

      validate :user_allowed_to_manage
      validate :assignee_is_possible
      validate :selected_cases_in_project
      validate :filter_options_in_project

      def self.manage_permission
        :add_test_runs
      end

      private

      def user_allowed_to_manage
        return if model.project.nil?

        errors.add :base, :error_unauthorized unless user.allowed_in_project?(self.class.manage_permission, model.project)
      end

      def assignee_is_possible
        return if model.assigned_to_id.blank? || model.project.nil?
        return unless model.will_save_change_to_assigned_to_id?

        possible = TestManagement::Assignees.possible?(model.project, model.assigned_to_id)
        errors.add :assigned_to, :invalid unless possible
      end

      def selected_cases_in_project
        ids = Array(model.selected_case_ids)
        return if ids.empty? || model.project.nil?

        found = model.project.tm_test_cases.where(id: ids).count
        errors.add :selected_case_ids, :invalid if found != ids.uniq.size
      end

      def filter_options_in_project
        return if model.project.nil?

        suite_ids = model.filter_suite_ids
        if suite_ids.any? && model.project.tm_suites.where(id: suite_ids).count != suite_ids.uniq.size
          errors.add :filter_options, :invalid
        end
      end
    end
  end
end
