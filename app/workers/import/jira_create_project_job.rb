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
  class JiraCreateProjectJob < ApplicationJob
    include Import::JiraOpenProjectReferenceCreation
    include ::Import::JiraCreateProjectsJob::JiraImportCustomFields

    def text
      jira_project_name = Import::JiraProject.find(arguments[1]).payload["name"]
      "Create project '#{jira_project_name}'"
    end

    # rubocop:disable Metrics/AbcSize
    def perform(jira_import_id, jira_project_id)
      Journal::NotificationConfiguration.with(false) do
        Journal::EventConfiguration.with(false) do
          @jira_import = Import::JiraImport.find(jira_import_id)
          jira = @jira_import.jira
          @jira_id = jira.id
          @system_user = User.system
          @jira_client = Import::JiraClient.new(url: jira.url, personal_access_token: jira.personal_access_token)
          jira_project = Import::JiraProject.find(jira_project_id)

          @project_role = Role.find_by!(name: "JiraMember")
          custom_field_registry = build_custom_field_registry

          ActiveRecord::Base.transaction do
            project = create_project(jira_project)
            update_custom_fields_in_project(project, jira_project, custom_field_registry)
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    # rubocop:disable Metrics/AbcSize
    def create_project(jira_project)
      project_key = jira_project.payload.fetch("key")
      project_keys = jira_project.payload.fetch("projectKeys")
      service_call = Projects::CreateService
                       .new(user: @system_user, contract_class: EmptyContract)
                       .call(
                         name: jira_project.payload.fetch("name"),
                         identifier: project_key,
                         description: jira_project.payload.fetch("description"),
                         active: true,
                         public: false,
                         parent: nil,
                         status_code: nil,
                         status_explanation: nil,
                         templated: false,
                         workspace_type: "project"
                       )
      if service_call.success?
        project = service_call.result
        insert_data = project_keys.map do |key|
          { sluggable_id: project.id,
            sluggable_type: project.class.to_s,
            slug: key,
            scope: nil }
        end
        FriendlyId::Slug.insert_all(insert_data, unique_by: %i[slug sluggable_type scope]) if insert_data.present?
        create_reference!(op_leg: project, jira_leg: jira_project, jira_import: @jira_import, uses_existing: false)
        return project
      end

      if (error = service_call.errors.find { |e| e.attribute == :identifier && e.type == :taken }) && error.present?
        taken_identifier = error.options[:value]
        raise I18n.t(:"admin.jira.run.project_identifier_taken", taken_identifier:)
      end

      raise service_call.message
    end
    # rubocop:enable Metrics/AbcSize

    def import_issue(jira_issue, project, custom_field_registry)
      type = import_type(jira_issue, project)
      status = import_status(jira_issue)
      update_workflows(type)
      new_custom_fields = new_custom_fields_in_type(jira_issue, type, custom_field_registry)
      update_custom_fields_in_type(type, new_custom_fields) if new_custom_fields.any?
      priority = import_priority(jira_issue) || IssuePriority.default || IssuePriority.active.first
      raise "Create a priority. OpenProject work package requires a priority!" if priority.blank?

      import_work_package(jira_issue, project, type, status, priority, custom_field_registry)
    end

    # rubocop:disable Metrics/AbcSize
    def update_custom_fields_in_project(project, jira_project, custom_field_registry)
      project_key = jira_project.payload["key"]
      applicable_cfs = custom_field_registry.flat_map do |entry|
        entry[:contexts]
          .select { |ctx| context_applies_to_project?(ctx, project_key) }
          .map { |ctx| ctx[:custom_field] }
      end
      existing_cf_ids = project.work_package_custom_fields.pluck(:id).to_set
      new_cfs = applicable_cfs.uniq.reject { |cf| existing_cf_ids.include?(cf.id) }
      project.work_package_custom_fields << new_cfs if new_cfs.any?
    end
    # rubocop:enable Metrics/AbcSize
  end
end
