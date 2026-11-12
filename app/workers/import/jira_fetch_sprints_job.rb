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
  class JiraFetchSprintsJob < ProgressableJob
    include JiraJobUtils

    BOARDS_PHASE = "boards"
    ISSUES_PHASE = "issues"
    ISSUE_BATCH_SIZE = 50

    def text
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title")
    end

    def progress
      cursor = Import::JiraImport.find(arguments[0]).get_job_cursor(self)
      return { current: 0, total: 0, percentage: 0 } if cursor.blank? || cursor["total"].to_i.zero?

      current = cursor["current"]
      total = cursor["total"]
      { current:, total:, percentage: (current.to_f / total * 100).round(2) }
    end

    def build_enumerator(jira_import_id, cursor:)
      prepare_jira_import_ivars(jira_import_id)
      cursor ||= @jira_import.get_job_cursor(self)

      Enumerator.new do |yielder|
        if cursor.nil? || cursor["phase"] == BOARDS_PHASE
          enumerate_phase(yielder, BOARDS_PHASE, scrum_board_ids, cursor)
          cursor = nil
        end
        enumerate_phase(yielder, ISSUES_PHASE, issue_batch_start_ids, cursor)
      end
    end

    def each_iteration((phase, id, cursor), _jira_import_id)
      if phase == BOARDS_PHASE
        fetch_board_sprints(Import::JiraBoard.find(id))
      else
        fetch_unstaged_sprints_of_issues(id)
      end
      @jira_import.set_job_cursor(self, cursor)
    end

    private

    def enumerate_phase(yielder, phase, ids, cursor)
      remaining = cursor ? ids.select { |id| id.to_i > cursor["position"].to_i } : ids
      done = ids.size - remaining.size
      remaining.each.with_index(done + 1) do |id, current|
        new_cursor = { "phase" => phase, "position" => id, "current" => current, "total" => ids.size }
        yielder.yield([phase, id, new_cursor], new_cursor)
      end
    end

    def scrum_board_ids
      Import::JiraBoard
        .where(jira_import_id: @jira_import.id)
        .where("payload ->> 'type' = 'scrum'")
        .order(:id)
        .pluck(:id)
    end

    def issues
      Import::JiraIssue.where(jira_import_id: @jira_import.id).order(:id)
    end

    def issue_batch_start_ids
      issues.pluck(:id).each_slice(ISSUE_BATCH_SIZE).map(&:first)
    end

    # Sprints on issues that no reachable scrum board covers, e.g. of projects without boards.
    def fetch_unstaged_sprints_of_issues(start_id)
      sprint_ids = sprint_field.sprint_ids(issues.where(id: start_id..).limit(ISSUE_BATCH_SIZE))
      staged = Import::JiraSprint.where(jira_import_id: @jira_import.id, origin_id: sprint_ids).pluck(:origin_id)
      (sprint_ids - staged - unavailable_sprint_ids.to_a).each { |sprint_id| fetch_sprint(sprint_id) }
    end

    def sprint_field
      @sprint_field ||= Import::JiraIssueSprintField.from_client(@jira_client)
    end

    def fetch_board_sprints(board)
      @jira_client.board_sprint_pages(board_id: board.origin_id).each do |sprints, _response, _next_start_at|
        upsert_sprints(sprints)
      end
    rescue Import::JiraClient::UnsupportedEndpointError => e
      log(board.origin_id) { Rails.logger.warn "Skipping sprints of board: #{e.message}" }
    end

    def fetch_sprint(origin_id)
      upsert_sprints([@jira_client.sprint(origin_id)])
    rescue Import::JiraClient::UnsupportedEndpointError => e
      unavailable_sprint_ids << origin_id
      log(origin_id) { Rails.logger.warn "Skipping sprint: #{e.message}" }
    end

    def unavailable_sprint_ids
      @unavailable_sprint_ids ||= Set.new
    end

    def upsert_sprints(sprints)
      return if sprints.empty?

      Import::JiraSprint.upsert_all(
        sprints.map do |payload|
          { payload:, origin_id: payload.fetch("id").to_s, jira_import_id: @jira_import.id,
            created_at: @created_at, updated_at: @updated_at }
        end,
        unique_by: %i[jira_import_id origin_id]
      )
    end

    def log(origin_id, &)
      tagged_log("jira_import_id:#{@jira_import.id}", "jira_object_type:sprint", "jira_object_id_or_name:#{origin_id}", &)
    end
  end
end
