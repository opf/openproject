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
  class JiraStagedImportJob < ApplicationJob
    include Import::JiraImportLogging

    def perform(batch, _context)
      with_jira_log_tags(jira_import_id: batch.properties[:jira_import_id]) { perform_stage(batch) }
    end

    private

    # rubocop:disable-next Metrics/AbcSize, Metrics/PerceivedComplexity
    def perform_stage(batch)
      jira_import = Import::JiraImport.find(batch.properties[:jira_import_id])

      if batch.succeeded?
        # happens when jobs are not progressable and can't react to impot_aborting by discarding themselves.
        if jira_import.in_state?(:import_aborting)
          Rails.logger.info "Import is aborting, not enqueueing further stages"
          jira_import.transition_to!(:import_error)
          return
        end

        if batch.properties[:stage].nil?
          Rails.logger.info "Entering stage 1: fetching issue types, priorities, statuses and projects"
          batch.enqueue(stage: 1) do
            Import::JiraFetchIssueTypesJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
            Import::JiraFetchPrioritiesJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
            Import::JiraFetchStatusesJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
            Import::JiraFetchProjectsJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 1
          Rails.logger.info "Entering stage 2: fetching issues per project"
          batch.enqueue(stage: 2) do
            Import::JiraProject.where(jira_import_id: jira_import.id,
                                      origin_id: jira_import.project_ids).pluck(:id).each do |id|
              Import::JiraFetchProjectIssuesJob.set(good_job_labels: ["stage_2"]).perform_later(jira_import.id, id)
            end
          end
        elsif batch.properties[:stage] == 2
          Rails.logger.info "Entering stage 3: fetching users and custom fields"
          batch.enqueue(stage: 3) do
            Import::JiraFetchUsersJob.set(good_job_labels: ["stage_3"]).perform_later(jira_import.id)
            Import::JiraFetchCustomFieldJob.set(good_job_labels: ["stage_3"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 3
          Rails.logger.info "Entering stage 4: creating users"
          batch.enqueue(stage: 4) do
            Import::JiraCreateUsersJob.set(good_job_labels: ["stage_4"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 4
          Rails.logger.info "Entering stage 5: creating project role and custom fields"
          batch.enqueue(stage: 5) do
            Import::JiraCreateProjectRoleJob.set(good_job_labels: ["stage_5"]).perform_later(jira_import.id)
            Import::JiraCreateCustomFieldsJob.set(good_job_labels: ["stage_5"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 5
          Rails.logger.info "Entering stage 6: creating projects"
          batch.enqueue(stage: 6) do
            Import::JiraProject.where(jira_import_id: jira_import.id,
                                      origin_id: jira_import.project_ids).find_each do |jira_project|
              Import::JiraCreateProjectJob.set(good_job_labels: ["stage_6"]).perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 6
          Rails.logger.info "Entering stage 7: creating work packages"
          batch.enqueue(stage: 7) do
            Import::JiraProject.where(jira_import_id: jira_import.id,
                                      origin_id: jira_import.project_ids).find_each do |jira_project|
              Import::JiraCreateProjectWorkPackagesJob.set(good_job_labels: ["stage_7"])
                .perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 7
          Rails.logger.info "Entering stage 8: downloading work package attachments"
          batch.enqueue(stage: 8) do
            Import::JiraProject.where(jira_import_id: jira_import.id,
                                      origin_id: jira_import.project_ids).find_each do |jira_project|
              Import::JiraCreateProjectWorkPackageAttachmentsJob.set(good_job_labels: ["stage_8"])
                .perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 8
          Rails.logger.info "All stages finished"
          jira_import.transition_to!(:imported)
        end
      elsif batch.discarded?
        Rails.logger.error "Import batch was discarded"
        jira_import.transition_to!(:import_error)
      end
    end
  end
end
