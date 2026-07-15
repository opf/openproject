module Import
  class BatchJob < ApplicationJob
    class FinishCallbackJob < ApplicationJob
      def perform(batch, context)
        jira_import = Import::JiraImport.find(batch.properties[:jira_import_id])

        case context[:event]
        when :finish
          if jira_import.in_state?(:import_cancelling)
            jira_import.transition_to!(:import_cancelled)
          end
        end
      end
    end

    class DiscardCallbackJob < ApplicationJob
      def perform(batch, context)
        jira_import = Import::JiraImport.find(batch.properties[:jira_import_id])
        case context[:event]
        when :discard
          jira_import.transition_to!(:import_error) unless jira_import.in_state?(:import_cancelling)
        end
      end
    end

    def perform(batch, context)
      jira_import = Import::JiraImport.find(batch.properties[:jira_import_id])

      case context[:event]
      when :success
        if batch.properties[:stage].nil?
          batch.enqueue(stage: 1) do
            Import::JiraFetchIssueTypesJob.perform_later(jira_import.id)
            Import::JiraFetchPrioritiesJob.perform_later(jira_import.id)
            Import::JiraFetchStatusesJob.perform_later(jira_import.id)
            Import::JiraFetchProjectsJob.perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 1
          batch.enqueue(stage: 2) do
            Import::JiraProject.where(jira_id: jira_import.jira_id, jira_project_id: jira_import.project_ids).pluck(:id).each do |jira_project_id|
              Import::JiraFetchProjectIssuesJob.perform_later(jira_import.id, jira_project_id)
            end
          end
        elsif batch.properties[:stage] == 2
          batch.enqueue(stage: 3) do
            Import::JiraFetchUsersJob.perform_later(jira_import.id)
            Import::JiraFetchCustomFieldJob.perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 3
          batch.enqueue(stage: 4) do
            Import::JiraCreateUsersJob.perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 4
          batch.enqueue(stage: 5) do
            Import::JiraCreateProjectRoleJob.perform_later(jira_import.id)
          end
        elsif batch.properties[:stage] == 5
          batch.enqueue(stage: 6) do
            Import::JiraProject.where(jira_import_id: jira_import.id,
                                      jira_project_id: jira_import.project_ids).find_each do |jira_project|
              Import::JiraCreateProjectJob.perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 6
          batch.enqueue(stage: 7) do
            Import::JiraProject.where(jira_import_id: jira_import.id,
                                      jira_project_id: jira_import.project_ids).find_each do |jira_project|
              Import::JiraCreateProjectWorkPackagesJob.perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 7
          batch.enqueue(stage: 8) do
            Import::JiraProject.where(jira_import_id: jira_import.id,
                                      jira_project_id: jira_import.project_ids).find_each do |jira_project|
              Import::JiraCreateProjectWorkPackageAttachmentsJob.perform_later(jira_import.id, jira_project.id)
            end
          end
        elsif batch.properties[:stage] == 8
          jira_import.transition_to!(:imported)
        end
      end
    end
  end
end
