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
  class JiraCreateSprintsJob < ProgressableJob
    include JiraOpenProjectReferenceCreation
    include JiraJobUtils

    ISSUE_BATCH_SIZE = 1_000
    ORIGIN_SOURCE = "jira_data_center"
    STATUSES = {
      "future" => "in_planning",
      "active" => "active",
      "closed" => "completed"
    }.freeze

    on_complete do
      tagged_log("jira_import_id:#{arguments[0]}", "jira_object_type:sprint") do
        Rails.logger.debug "Creating sprints finished"
      end
    end

    def text
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title")
    end

    def progress
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      return { current: 0, total: 0, percentage: 0 } if cursor.blank?

      sprints = Import::JiraSprint.where(jira_import:)
      total = sprints.count
      current = sprints.where(id: ..cursor).count
      { current:, total:, percentage: (current.to_f / total * 100).round(2) }
    end

    def build_enumerator(jira_import_id, cursor:)
      prepare_jira_import_ivars(jira_import_id)
      log { Rails.logger.debug "Creating sprints started" }
      @issue_counts = issue_counts_by_sprint

      enumerator_builder.active_record_on_records(
        Import::JiraSprint.where(jira_import_id:),
        cursor: cursor || @jira_import.get_job_cursor(self)
      )
    end

    def each_iteration(jira_sprint, _jira_import_id)
      counts = @issue_counts[jira_sprint.origin_id]
      ActiveRecord::Base.transaction do
        import_sprint(jira_sprint, counts) if counts
        @jira_import.set_job_cursor(self, jira_sprint.id)
      end
    end

    private

    def import_sprint(jira_sprint, counts)
      existing_sprint = earlier_imported_sprint(jira_sprint)
      sprint = existing_sprint || create_sprint(jira_sprint, counts)
      counts.each_key { |jira_project_id| enable_backlogs(op_project(jira_project_id)) }
      create_reference!(op_leg: sprint, jira_leg: jira_sprint, jira_import: @jira_import,
                        uses_existing: existing_sprint.present?)
    end

    def earlier_imported_sprint(jira_sprint)
      sprint = Sprint.find_by(origin_source: ORIGIN_SOURCE, origin_host:, origin_id: jira_sprint.origin_id)
      log(jira_sprint.origin_id) { Rails.logger.debug "Reusing sprint of an earlier import" } if sprint
      sprint
    end

    def origin_host
      @jira_import.jira.url
    end

    def origin_url(payload)
      base_url = origin_host.chomp("/")
      board_id = payload["originBoardId"]
      return "#{base_url}/rest/agile/1.0/sprint/#{payload['id']}" if board_id.blank?

      "#{base_url}/secure/RapidBoard.jspa?rapidView=#{board_id}&view=reporting&chart=sprintRetrospective&sprint=#{payload['id']}"
    end

    def issue_counts_by_sprint
      sprint_field = Import::JiraIssueSprintField.from_client(@jira_client)
      counts = {}
      Import::JiraIssue.where(jira_import_id: @jira_import.id).in_batches(of: ISSUE_BATCH_SIZE) do |issues|
        sprint_field.each_issue_sprint_ids(issues) do |jira_project_id, sprint_ids|
          sprint_ids.each { |sprint_id| (counts[sprint_id] ||= Hash.new(0))[jira_project_id] += 1 }
        end
      end
      counts
    end

    def create_sprint(jira_sprint, counts)
      payload = jira_sprint.payload
      project = owning_project(counts)
      attributes = sprint_attributes(payload)
      allow_multiple_active_sprints(project) if attributes[:status] == "active"

      sprint = Sprint.create!(project:, **attributes, **origin_attributes(jira_sprint))
      create_goal(sprint, payload["goal"])
      sprint
    end

    def origin_attributes(jira_sprint)
      { origin_source: ORIGIN_SOURCE, origin_host:, origin_id: jira_sprint.origin_id,
        origin_url: origin_url(jira_sprint.payload) }
    end

    # project with most issues wins, ties go to the project key that sorts first.
    def owning_project(counts)
      jira_project_id = counts.min_by { |id, count| [-count, staged_project(id).payload["key"]] }.first
      op_project(jira_project_id)
    end

    def op_project(jira_project_id)
      @op_projects ||= {}
      @op_projects[jira_project_id] ||= @jira_import.find_op_leg!(staged_project(jira_project_id))
    end

    def staged_project(jira_project_id)
      @staged_projects ||= Import::JiraProject.where(jira_import_id: @jira_import.id).index_by(&:id)
      @staged_projects.fetch(jira_project_id)
    end

    def sprint_attributes(payload)
      start_date = to_date(payload["startDate"])
      finish_date = to_date(payload["endDate"])
      finish_date = [finish_date, start_date].max if start_date && finish_date
      {
        name: payload["name"].presence || "Sprint #{payload['id']}",
        status: sprint_status(payload, start_date, finish_date),
        start_date:,
        finish_date:,
        started_at: to_time(payload["activatedDate"]),
        completed_at: to_time(payload["completeDate"])
      }
    end

    def sprint_status(payload, start_date, finish_date)
      status = STATUSES.fetch(payload["state"].to_s.downcase, "in_planning")
      return status unless status == "active" && (start_date.nil? || finish_date.nil?)

      log(payload["id"]) { Rails.logger.warn "Active sprint without start or end date is imported as in planning" }
      "in_planning"
    end

    def create_goal(sprint, goal)
      return if goal.blank?

      SprintGoal.create!(sprint:, project: sprint.project, text: goal.truncate(SprintGoal::TEXT_MAX_LENGTH))
    end

    def allow_multiple_active_sprints(project)
      return if project.allow_multiple_active_sprints? || !Sprint.for_project(project).active.exists?

      project.update!(allow_multiple_active_sprints: true)
      log { Rails.logger.warn "Project #{project.identifier} owns several active sprints, multiple active sprints are allowed" }
    end

    def enable_backlogs(project)
      project.enabled_modules.create!(name: "backlogs") unless project.module_enabled?(:backlogs)
    end

    def to_time(value)
      Import::JiraSprintValueParser.parse_time(value)
    end

    def to_date(value)
      Import::JiraSprintValueParser.parse_date(value)
    end

    def log(origin_id = nil, &)
      tags = %W[jira_import_id:#{@jira_import.id} jira_object_type:sprint]
      tags << "jira_object_id_or_name:#{origin_id}" if origin_id
      tagged_log(*tags, &)
    end
  end
end
