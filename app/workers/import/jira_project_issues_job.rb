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

module Import
  module JiraProjectIssuesJob
    def progress
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      if cursor.present?
        issues = issues_to_process(jira_import, arguments[1])
        total = issues.count
        current = issues.where(id: ..cursor).count
        percentage = (current.to_f / total * 100).round(2)
        { current:, total:, percentage: }
      else
        { current: 0, total: 0, percentage: 0 }
      end
    end

    private

    # Jobs that only process some of the issues narrow this down, so progress counts the same ones.
    def issues_to_process(jira_import, jira_project_id)
      Import::JiraIssue.where(jira_import:, jira_project_id:)
    end

    def create_member(project, user)
      raise "#{self.class} must set @system_user and @project_role to create members" unless @system_user && @project_role

      service_call = Members::CreateService
                       .new(user: @system_user, contract_class: EmptyContract)
                       .call(
                         project:,
                         roles: [@project_role],
                         user_id: user.id,
                         principal: user
                       )
      return if service_call.success?

      if service_call.errors.find { |error| error.type == :taken }.blank?
        Rails.logger.error service_call.message
        raise service_call.message
      end
    end
  end
end
