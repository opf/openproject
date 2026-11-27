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
  class JiraFetchProjectBoardsJob < ProgressableJob
    include JiraJobUtils

    def text
      jira_project_name = Import::JiraProject.find(arguments[1]).payload["name"]
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title", jira_project_name:)
    end

    def progress
      cursor = Import::JiraImport.find(arguments[0]).get_job_cursor(self)
      return { current: 0, total: 0, percentage: 0 } if cursor.blank? || cursor["total"].to_i.zero?

      current = cursor["start_at"]
      total = cursor["total"]
      { current:, total:, percentage: (current.to_f / total * 100).round(2) }
    end

    def build_enumerator(jira_import_id, jira_project_id, cursor:)
      prepare_jira_import_ivars(jira_import_id)
      start_at = (cursor || @jira_import.get_job_cursor(self))&.dig("start_at") || 0

      Enumerator.new do |yielder|
        each_board_page(jira_project_id, start_at) do |boards, response, next_start_at|
          cursor = { "start_at" => next_start_at, "total" => response["total"] }
          yielder.yield([boards, cursor], cursor)
        end
      end
    end

    def each_iteration((boards, cursor), jira_import_id, jira_project_id)
      log(jira_import_id, jira_project_id) { Rails.logger.debug { "Fetched #{boards.size} boards" } }
      Import::JiraBoard.upsert_all(
        boards.map do |payload|
          { payload:, origin_id: payload.fetch("id").to_s, jira_import_id:, created_at: @created_at, updated_at: @updated_at }
        end,
        unique_by: %i[jira_import_id origin_id]
      )
      @jira_import.set_job_cursor(self, cursor)
    end

    private

    def each_board_page(jira_project_id, start_at, &)
      @jira_client.board_pages(project_id_or_key: jira_project(jira_project_id).origin_id, start_at:).each(&)
    rescue Import::JiraClient::UnsupportedEndpointError => e
      log(@jira_import.id, jira_project_id) do
        Rails.logger.warn "Jira Agile API unavailable, no sprints are imported: #{e.message}"
      end
    rescue Import::JiraClient::ApiError => e
      raise unless e.status == 400

      log(@jira_import.id, jira_project_id) do
        Rails.logger.warn "Skipping boards of a project Jira no longer finds: #{e.message}"
      end
    end

    def log(jira_import_id, jira_project_id, &)
      tagged_log("jira_import_id:#{jira_import_id}", "jira_project_id:#{jira_project_key(jira_project_id)}",
                 "jira_object_type:board", &)
    end
  end
end
