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
    class FinishCallbackJob < ApplicationJob
      def perform(batch, context)
        jira_import = Import::JiraImport.find(batch.properties[:jira_import_id])

        case context[:event]
        when :finish
          if jira_import.in_state?(:import_aborting)
            jira_import.transition_to!(:import_error)
          end
        end
      end
    end

    class DiscardCallbackJob < ApplicationJob
      def perform(batch, context)
        jira_import = Import::JiraImport.find(batch.properties[:jira_import_id])
        case context[:event]
        when :discard
          jira_import.transition_to!(:import_error) unless jira_import.in_state?(:import_aborting, :import_error)
        end
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    def perform(batch, context)
      jira_import = Import::JiraImport.find(batch.properties[:jira_import_id])

      case context[:event]
      when :success
        if batch.properties[:stage].nil?
          batch.enqueue(stage: 1) do
            Import::JiraFetchIssueTypesJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
            Import::JiraFetchPrioritiesJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
            Import::JiraFetchStatusesJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
            Import::JiraFetchProjectsJob.set(good_job_labels: ["stage_1"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 1
          batch.enqueue(stage: 2) do
            Import::JiraProject.where(jira_import_id: jira_import.id,
                                      origin_id: jira_import.project_ids).pluck(:id).each do |id|
              Import::JiraFetchProjectIssuesJob.set(good_job_labels: ["stage_2"]).perform_later(jira_import.id, id)
            end
          end
        elsif batch.properties[:stage] == 2
          batch.enqueue(stage: 3) do
            Import::JiraFetchUsersJob.set(good_job_labels: ["stage_3"]).perform_later(jira_import.id)
            Import::JiraFetchCustomFieldJob.set(good_job_labels: ["stage_3"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 3
          batch.enqueue(stage: 4) do
            Import::JiraCreateUsersJob.set(good_job_labels: ["stage_4"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 4
          batch.enqueue(stage: 5) do
            Import::JiraCreateProjectRoleJob.set(good_job_labels: ["stage_5"]).perform_later(jira_import.id)
            Import::JiraCreateCustomFieldsJob.set(good_job_labels: ["stage_5"]).perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 5
          batch.enqueue(stage: 6) do
            Import::JiraProject.where(jira_import_id: jira_import.id,
                                      origin_id: jira_import.project_ids).find_each do |jira_project|
              Import::JiraCreateProjectJob.set(good_job_labels: ["stage_6"]).perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 6
          batch.enqueue(stage: 7) do
            Import::JiraProject.where(jira_import_id: jira_import.id,
                                      origin_id: jira_import.project_ids).find_each do |jira_project|
              Import::JiraCreateProjectWorkPackagesJob.set(good_job_labels: ["stage_7"])
                                                      .perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 7
          batch.enqueue(stage: 8) do
            Import::JiraProject.where(jira_import_id: jira_import.id,
                                      origin_id: jira_import.project_ids).find_each do |jira_project|
              Import::JiraCreateProjectWorkPackageAttachmentsJob.set(good_job_labels: ["stage_8"])
                                                                .perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 8
          jira_import.transition_to!(:imported)
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity
  end
end
