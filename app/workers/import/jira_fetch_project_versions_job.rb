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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Import
  class JiraFetchProjectVersionsJob < ProgressableJob
    include JiraJobUtils

    def text
      jira_project_name = Import::JiraProject.find(arguments[1]).payload["name"]
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title", jira_project_name:)
    end

    def progress
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      if cursor.present?
        current = cursor["start_at"]
        total = cursor["total"]
        percentage = (current.to_f / total * 100).round(2)
        { current:, total:, percentage: }
      else
        { current: 0, total: 0, percentage: 0 }
      end
    end

    # rubocop:disable Metrics/AbcSize
    def build_enumerator(jira_import_id, jira_project_id, cursor:)
      jira_project = jira_project(jira_project_id)
      Rails.logger.tagged("batch_id:#{batch_id}", "jira_import_id:#{jira_import_id}",
                          "jira_project_id:#{jira_project.payload['key']}", "jira_object_type:version") do
        Rails.logger.debug "Fetching project versions started"
      end
      prepare_jira_import_ivars(jira_import_id)

      cursor ||= @jira_import.get_job_cursor(self)
      start_at = cursor&.dig("start_at") || 0

      Enumerator.new do |yielder|
        loop do
          response = @jira_client.project_versions(
            project_id_or_key: jira_project.origin_id,
            start_at:,
            max_results: 100
          )

          versions = response["values"]
          total = response["total"]

          break if versions.empty?

          new_cursor = { "start_at" => start_at, "total" => total }
          versions_and_total = { "versions" => versions, "total" => total }

          @jira_import.set_job_cursor(self, new_cursor)

          # This loop body runs later, inside the Enumerator's own Fiber, once build_enumerator has
          # already returned and the tagged block above has already closed - so it needs its own
          # full set of tags rather than nesting inside (and inheriting from) that one.
          Rails.logger.tagged("batch_id:#{batch_id}", "jira_import_id:#{jira_import_id}",
                              "jira_project_id:#{jira_project.payload['key']}", "jira_object_type:version") do
            Rails.logger.debug { "Fetched #{start_at + versions.size} of #{total} project versions" }
          end

          yielder.yield(
            versions_and_total,
            new_cursor
          )

          start_at += versions.size
        end
      end
    end

    def each_iteration(versions_and_total, jira_import_id, jira_project_id)
      versions = versions_and_total["versions"]
      versions_upsert_data = Rails.logger.tagged("batch_id:#{batch_id}", "jira_import_id:#{jira_import_id}",
                                                 "jira_project_id:#{jira_project_key(jira_project_id)}",
                                                 "jira_object_type:version") do
        versions.map do |payload|
          Rails.logger.tagged("jira_object_id_or_name:#{payload['name']}") do
            Rails.logger.debug "Fetched project version"
          end
          {
            payload:,
            jira_project_id:,
            origin_id: payload.fetch("id"),
            jira_import_id:,
            created_at: @created_at,
            updated_at: @updated_at
          }
        end
      end
      Import::JiraVersion.upsert_all(versions_upsert_data, unique_by: %i[jira_import_id origin_id])
    end
    # rubocop:enable Metrics/AbcSize
  end
end
