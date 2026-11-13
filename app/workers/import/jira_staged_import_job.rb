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
  class JiraStagedImportJob < ApplicationJob
    include JobLogging

    def perform(batch, _context)
      jira_import = Import::JiraImport.find(batch.properties[:jira_import_id])
      perform_stage(batch, jira_import)
    end

    private

    def log_context
      batch = arguments.first
      { batch_id: batch.id, jira_import_id: batch.properties[:jira_import_id] }
    end

    # rubocop:disable-next Metrics/AbcSize, Metrics/PerceivedComplexity
    def perform_stage(batch, jira_import)
      if batch.succeeded?
        # happens when jobs are not progressable and can't react to import_aborting by discarding themselves.
        if jira_import.in_state?(:import_aborting)
          Rails.logger.warn "Import is aborting, stopping the staged import"
          jira_import.transition_to!(:import_error)
          return
        end

        if batch.properties[:stage].nil?
          start_stage(batch, 1) do
            Import::JiraFetchIssueTypesJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
            Import::JiraFetchPrioritiesJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
            Import::JiraFetchStatusesJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
            Import::JiraFetchProjectsJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 1
          start_stage(batch, 2) do
            find_each_imported_project(jira_import) do |jira_project|
              Import::JiraFetchProjectIssuesJob.set(good_job_labels: ["stage_2"]).perform_later(jira_import.id, jira_project.id)
              Import::JiraFetchProjectVersionsJob.set(good_job_labels: ["stage_2"]).perform_later(jira_import.id, jira_project.id)
              Import::JiraFetchProjectBoardsJob.set(good_job_labels: ["stage_2"]).perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 2
          start_stage(batch, 3) do
            Import::JiraFetchUsersJob.set(good_job_labels: ["stage_3"]).perform_later(jira_import.id)
            Import::JiraFetchCustomFieldJob.set(good_job_labels: ["stage_3"]).perform_later(jira_import.id)
            Import::JiraFetchSprintsJob.set(good_job_labels: ["stage_3"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 3
          start_stage(batch, 4) do
            Import::JiraCreateUsersJob.set(good_job_labels: ["stage_4"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 4
          start_stage(batch, 5) do
            Import::JiraCreateProjectRoleJob.set(good_job_labels: ["stage_5"]).perform_later(jira_import.id)
            Import::JiraCreateCustomFieldsJob.set(good_job_labels: ["stage_5"]).perform_later(jira_import.id)
            Import::JiraCreateLabelsJob.set(good_job_labels: ["stage_5"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 5
          start_stage(batch, 6) do
            find_each_imported_project(jira_import) do |jira_project|
              Import::JiraCreateProjectJob.set(good_job_labels: ["stage_6"]).perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 6
          start_stage(batch, 7) do
            find_each_imported_project(jira_import) do |jira_project|
              Import::JiraCreateProjectVersionsJob
                .set(good_job_labels: ["stage_7"])
                .perform_later(jira_import.id, jira_project.id)
            end
            Import::JiraCreateSprintsJob.set(good_job_labels: ["stage_7"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 7
          start_stage(batch, 8) do
            find_each_imported_project(jira_import) do |jira_project|
              Import::JiraCreateProjectWorkPackagesJob.set(good_job_labels: ["stage_8"])
                .perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 8
          start_stage(batch, 9) do
            find_each_imported_project(jira_import) do |jira_project|
              Import::JiraCreateParentChildRelationsFromSubtasksJob.set(good_job_labels: ["stage_9"])
                .perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 9
          start_stage(batch, 10) do
            find_each_imported_project(jira_import) do |jira_project|
              Import::JiraCreateRelationsJob.set(good_job_labels: ["stage_10"])
                .perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 10
          start_stage(batch, 11) do
            find_each_imported_project(jira_import) do |jira_project|
              Import::JiraCreateProjectTimeEntriesJob.set(good_job_labels: ["stage_11"])
                .perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 11
          start_stage(batch, 12) do
            find_each_imported_project(jira_import) do |jira_project|
              Import::JiraDownloadProjectWorkPackageAttachmentsJob.set(good_job_labels: ["stage_12"])
                .perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 12
          Rails.logger.info "Import finished"
          jira_import.transition_to!(:imported)
        end
      elsif batch.discarded?
        Rails.logger.error "Staged import batch discarded, one or more jobs failed"
        jira_import.transition_to!(:import_error)
      end
    end

    def start_stage(batch, number, &)
      Rails.logger.info "Starting stage #{number}"
      batch.enqueue(stage: number, &)
    end

    def find_each_imported_project(jira_import, &)
      Import::JiraProject.where(jira_import_id: jira_import.id,
                                origin_id: jira_import.project_ids).find_each(&)
    end
  end
end
