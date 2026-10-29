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
  class JiraCreateProjectTimeEntriesJob < ProgressableJob
    include Import::JiraJobUtils
    include Import::JiraProjectIssuesJob

    on_complete do
      tagged_log("jira_import_id:#{arguments[0]}",
                 "jira_project_id:#{jira_project_key(arguments[1])}", "jira_object_type:project") do
        Rails.logger.debug "Creating time entries finished"
      end
    end

    def text
      jira_project_name = Import::JiraProject.find(arguments[1]).payload["name"]
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title", jira_project_name:)
    end

    def build_enumerator(jira_import_id, jira_project_id, cursor:)
      jira_project = jira_project(jira_project_id)
      tagged_log("jira_import_id:#{jira_import_id}",
                 "jira_project_id:#{jira_project_key(jira_project_id)}", "jira_object_type:project") do
        Rails.logger.debug "Creating time entries started"
        @jira_import = Import::JiraImport.find(jira_import_id)
        @system_user = User.system
        @project = @jira_import.find_op_leg!(jira_project)
        @project_role = Role.find_by!(name: "JiraMember")
        @project_users = {}

        cursor ||= @jira_import.get_job_cursor(self)
        enumerator_builder.active_record_on_records(
          issues_to_process(@jira_import, jira_project_id)
            .select(:id, "payload ->> 'key' AS key", "payload #> '{fields,worklog,worklogs}' AS worklogs"),
          cursor:
        )
      end
    end

    def each_iteration(jira_issue, jira_import_id, jira_project_id)
      tagged_log("jira_import_id:#{jira_import_id}",
                 "jira_project_id:#{jira_project_key(jira_project_id)}",
                 "jira_issue_key:#{jira_issue.key}") do
        Journal::NotificationConfiguration.with(false) do
          Journal::EventConfiguration.with(false) do
            ActiveRecord::Base.transaction do
              create_time_entries(jira_issue)
              @jira_import.set_job_cursor(self, jira_issue.id)
            end
          end
        end
      end
    end

    private

    def issues_to_process(jira_import, jira_project_id) = super.with_worklogs

    def create_time_entries(jira_issue)
      work_package = @jira_import.find_op_leg!(jira_issue)

      jira_issue.worklogs.each do |worklog|
        Rails.logger.tagged("jira_object_type:worklog", "jira_object_id_or_name:#{worklog['id']}") do
          Rails.logger.debug "Creating time entry"
          create_time_entry(work_package, worklog)
        end
      end
    end

    # rubocop:disable-next Metrics/AbcSize
    def create_time_entry(work_package, worklog)
      user = project_user(worklog.dig("author", "key"))
      started_at = user.time_zone.parse(worklog["started"])
      start_time = (started_at.hour * 60) + started_at.min

      call = TimeEntries::ImportCreateService
               .new(user:, contract_class: EmptyContract)
               .call(
                 user:,
                 entity: work_package,
                 hours: worklog["timeSpentSeconds"] / TimeEntry::SECONDS_PER_HOUR,
                 spent_on: started_at.to_date,
                 start_time:,
                 comments: worklog_comment(worklog),
                 created_at: Time.zone.parse(worklog["created"]),
                 updated_at: Time.zone.parse(worklog["updated"])
               )

      call.on_failure do
        Rails.logger.error "Time entry creation failed: #{call.message}"
        raise call.message
      end
    end

    def worklog_comment(worklog)
      comment = worklog["comment"]
      return comment if comment.nil? || comment.length <= TimeEntry::COMMENTS_MAX_LENGTH

      Rails.logger.warn "Shortening the worklog comment from #{comment.length} to #{TimeEntry::COMMENTS_MAX_LENGTH} characters"
      comment.truncate(TimeEntry::COMMENTS_MAX_LENGTH)
    end

    def project_user(jira_user_key)
      @project_users[jira_user_key] ||= begin
        user = find_user(jira_user_key)
        create_member(@project, user) unless user.is_a?(DeletedUser)
        user
      end
    end

    def find_user(jira_user_key)
      return if jira_user_key.blank?

      Rails.logger.tagged("jira_object_type:user", "jira_object_id_or_name:#{jira_user_key}") do
        jira_user = Import::JiraUser.find_by(origin_id: jira_user_key, jira_import: @jira_import)

        if jira_user
          @jira_import.find_op_leg!(jira_user)
        else
          Rails.logger.warn "Import::JiraUser with jira_user_key #{jira_user_key} not found! Using DeletedUser instead."
          DeletedUser.first
        end
      end
    end
  end
end
