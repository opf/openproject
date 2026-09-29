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
  class JiraCreateProjectVersionsJob < ProgressableJob
    include Import::JiraOpenProjectReferenceCreation

    def text
      jira_project_name = Import::JiraProject.find(arguments[1]).payload["name"]
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title", jira_project_name:)
    end

    def progress
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      if cursor.present?
        versions = Import::JiraVersion.where(jira_import:, jira_project_id: arguments[1])
        total = versions.count
        current = versions.where(id: ..cursor).count
        percentage = (current.to_f / total * 100).round(2)
        { current:, total:, percentage: }
      else
        { current: 0, total: 0, percentage: 0 }
      end
    end

    def build_enumerator(jira_import_id, jira_project_id, cursor:)
      @jira_import = Import::JiraImport.find(jira_import_id)
      @jira_import.jira
      jira_project = Import::JiraProject.find(jira_project_id)

      @project = JiraOpenProjectReference.find_by!(
        jira_entity_id: jira_project.id,
        jira_entity_class: jira_project.class.to_s
      ).op_leg

      cursor ||= @jira_import.get_job_cursor(self)
      enumerator_builder.active_record_on_records(
        Import::JiraVersion.where(jira_import_id:, jira_project_id:),
        cursor: cursor
      )
    end

    # rubocop:disable-next Metrics/AbcSize
    def each_iteration(jira_version, jira_import_id, jira_project_id)
      payload = jira_version.payload
      jira_version_name = payload.fetch("name")
      Rails.logger.tagged("jira_import_id:#{jira_import_id}",
                          "jira_project_id:#{jira_project_id}",
                          "jira_version_name:#{jira_version_name}") do
        ActiveRecord::Base.transaction do
          version = Version.create!(
            project_id: @project.id,
            name: jira_version_name,
            description: payload["description"],
            effective_date: payload["releaseDate"]&.to_date,
            start_date: payload["startDate"]&.to_date,
            status: payload.fetch("released") || payload.fetch("archived") ? "closed" : "open"
          )
          create_reference!(op_leg: version,
                            jira_leg: jira_version,
                            jira_import: @jira_import,
                            uses_existing: false)
          @jira_import.set_job_cursor(self, jira_version.id)
        end
      end
    end
  end
end
