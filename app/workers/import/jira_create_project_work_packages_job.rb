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
  class JiraCreateProjectWorkPackagesJob < ProgressableJob
    include Import::JiraOpenProjectReferenceCreation
    include ::Import::JiraCreateProjectJob::JiraImportCustomFields

    on_complete do
      # Update project.wp_sequence_counter to max sequence_number found in migrated from jira work_packages
      # or 0 in case there are no work_packages in the project.
      Project
        .where(id: @project.id)
        .update_all(["wp_sequence_counter = (SELECT COALESCE(MAX(sequence_number), 0) " \
                     "FROM work_packages WHERE project_id = ?)", @project.id])
    end

    def text
      jira_project_name = Import::JiraProject.find(arguments[1]).payload["name"]
      "Create work_packages for '#{jira_project_name}'"
    end

    def percentage
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      if cursor.present?
        issues = Import::JiraIssue.where(jira_import:, jira_project_id: arguments[1])
        total = issues.count
        position = issues.where(id: ..cursor).count
        (position.to_f / total * 100).round(2)
      else
        0
      end
    end

    # rubocop:disable Metrics/AbcSize
    def build_enumerator(jira_import_id, jira_project_id, cursor:)
      @jira_import = Import::JiraImport.find(jira_import_id)
      jira = @jira_import.jira
      @jira_id = jira.id
      @system_user = User.system
      @jira_client = Import::JiraClient.new(url: jira.url, personal_access_token: jira.personal_access_token)
      jira_project = Import::JiraProject.find(jira_project_id)

      @project_role = Role.find_by!(name: "JiraMember")
      @custom_field_registry = build_custom_field_registry

      @project = JiraOpenProjectReference.find_by!(
        jira_entity_id: jira_project.id,
        jira_entity_class: jira_project.class.to_s
      ).op_leg

      update_custom_fields_in_project(@project, jira_project, @custom_field_registry)

      cursor ||= @jira_import.get_job_cursor(self)
      enumerator_builder.active_record_on_records(
        Import::JiraIssue.where(jira_import_id:, jira_project_id:),
        cursor: cursor
      )
    end
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/AbcSize
    def each_iteration(jira_issue, _jira_import_id, _jira_project_id)
      Journal::NotificationConfiguration.with(false) do
        Journal::EventConfiguration.with(false) do
          ActiveRecord::Base.transaction do
            type = create_type(jira_issue, @project)
            status = create_status(jira_issue)
            update_workflows(type)
            new_custom_fields = new_custom_fields_in_type(jira_issue, type, @custom_field_registry)
            update_custom_fields_in_type(type, new_custom_fields) if new_custom_fields.any?
            priority = create_priority(jira_issue) || IssuePriority.default || IssuePriority.active.first
            raise "Create a priority. OpenProject work package requires a priority!" if priority.blank?

            create_work_package(jira_issue, @project, type, status, priority, @custom_field_registry)
            @jira_import.set_job_cursor(self, jira_issue.id)
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    def new_custom_fields_in_type(jira_issue, type, custom_field_registry)
      existing_cf_ids = type.default_variant.custom_field_ids
      custom_fields_for_issue(custom_field_registry, jira_issue).reject { |cf| existing_cf_ids.include?(cf.id) }
    end

    def update_custom_fields_in_type(type, new_custom_fields)
      variant = type.default_variant
      variant.custom_fields << new_custom_fields
      new_cf_keys = new_custom_fields.map(&:attribute_name)
      groups = variant.attribute_groups.map { |g| [g.key, g.is_a?(Type::QueryGroup) ? [g.query_attribute_name] : g.attributes] }

      remove_custom_fields_from_other_groups(groups, new_cf_keys)
      add_or_update_jira_import_group(groups, new_cf_keys)

      variant.attribute_groups = groups
      variant.save!
      variant.reload
    end

    def remove_custom_fields_from_other_groups(groups, cf_keys)
      groups.each do |group|
        next if group[0] == JIRA_IMPORT_GROUP_KEY

        group[1] -= cf_keys
      end
    end

    def add_or_update_jira_import_group(groups, cf_keys)
      jira_group = groups.find { |g| g[0] == JIRA_IMPORT_GROUP_KEY }
      if jira_group
        jira_group[1] |= cf_keys
      else
        groups << [JIRA_IMPORT_GROUP_KEY, cf_keys]
      end
    end

    def update_custom_fields_in_project(project, jira_project, custom_field_registry)
      applicable_cfs = Import::JiraIssue
                         .where(jira_import_id: @jira_import.id, jira_project_id: jira_project.id)
                         .flat_map { |jira_issue| custom_fields_for_issue(custom_field_registry, jira_issue) }
      existing_cf_ids = project.work_package_custom_fields.pluck(:id).to_set
      new_cfs = applicable_cfs.uniq.reject { |cf| existing_cf_ids.include?(cf.id) }
      project.work_package_custom_fields << new_cfs if new_cfs.any?
    end

    # rubocop:disable Metrics/AbcSize
    def create_type(jira_issue, project)
      issue_type = jira_issue.payload["fields"]["issuetype"]
      type = Type.where("LOWER(name) = LOWER(?)", issue_type["name"]).first
      uses_existing = true

      if type.blank?
        service_call = WorkPackageTypes::CreateService
                         .new(user: @system_user)
                         .call(name: issue_type["name"])
        raise service_call.message unless service_call.success?

        type = service_call.result
        uses_existing = false
      end

      enable_type(project, type)
      jira_issue_type = Import::JiraIssueType.find_by!(origin_id: issue_type["id"], jira_import_id: @jira_import.id)
      create_reference!(op_leg: type, jira_leg: jira_issue_type, jira_import: @jira_import, uses_existing:)
      type
    end
    # rubocop:enable Metrics/AbcSize

    def enable_type(project, type)
      service_call = Projects::Types::AddService
                       .new(user: @system_user, model: project)
                       .call(variant: type.default_variant)
      raise service_call.message if service_call.failure?
    end

    def create_status(jira_issue)
      issue_status = jira_issue.payload["fields"]["status"]
      status = Status.where("LOWER(name) = LOWER(?)", issue_status["name"]).first
      uses_existing = true
      if status.blank?
        status = Status.create!(name: issue_status["name"])
        uses_existing = false
      end
      jira_status = Import::JiraStatus.find_by!(origin_id: issue_status["id"], jira_import_id: @jira_import.id)
      create_reference!(op_leg: status, jira_leg: jira_status, jira_import: @jira_import, uses_existing:)
      status
    end

    def create_priority(jira_issue)
      issue_priority = jira_issue.payload["fields"]["priority"]
      if issue_priority.present?
        priority = IssuePriority.where("LOWER(name) = LOWER(?)", issue_priority["name"]).first
        uses_existing = true
        if priority.blank?
          priority = IssuePriority.create!(name: issue_priority["name"])
          uses_existing = false
        end
        jira_priority = Import::JiraPriority.find_by!(origin_id: issue_priority["id"], jira_import_id: @jira_import.id)
        create_reference!(op_leg: priority, jira_leg: jira_priority, jira_import: @jira_import, uses_existing:)
        priority
      end
    end

    def update_workflows(type)
      statuses = Status.all
      row = statuses.to_h { |status| [status.id.to_s, ["always"]] }
      status_params = statuses.to_h { |status| [status.id.to_s, row] }
      call = Workflows::BulkUpdateService
                .new(role: @project_role, variant: type.default_variant, tab: "always")
                .call(status_params)
      raise call.message if call.failure?
    end

    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    def create_work_package(jira_issue, project, type, status, priority, custom_field_registry)
      # required because otherwise project.types does not include type and then wp creation fails.
      project.reload

      author_key = jira_issue.payload.dig("fields", "creator", "key")
      author = find_user(author_key)
      assignee_key = jira_issue.payload.dig("fields", "assignee", "key")
      assigned_to = find_user(assignee_key)
      [author, assigned_to].uniq.compact.each { |member| create_member(project, member) }

      custom_field_attrs = collect_custom_field_attributes(custom_field_registry, jira_issue)

      original_estimate_seconds = jira_issue.payload.dig("fields", "timetracking", "originalEstimateSeconds")
      remaining_estimate_seconds = jira_issue.payload.dig("fields", "timetracking", "remainingEstimateSeconds")

      service_call =
        WorkPackages::CreateService
          .new(user: author || @system_user, contract_class: EmptyContract)
          .call(
            project:,
            subject: jira_issue.payload["fields"]["summary"],
            description: Import::JiraWikiMarkupConverter.new(jira_issue.payload["fields"]["description"] || "").convert,
            type:,
            priority:,
            status:,
            assigned_to:,
            due_date: jira_issue.payload.dig("fields", "duedate"),
            estimated_hours: (original_estimate_seconds / 3600.0 if original_estimate_seconds),
            remaining_hours: (remaining_estimate_seconds / 3600.0 if remaining_estimate_seconds),
            skip_semantic_id_allocation: true,
            **custom_field_attrs
          )
      raise service_call.message unless service_call.success?

      work_package = service_call.result
      identifier = jira_issue.payload["key"]
      _, sequence_number = identifier.split("-")
      work_package.update_columns(sequence_number:, identifier:)
      work_package_id = work_package.id
      aliases_from_history = jira_issue
                               .payload["changelog"]["histories"]
                               .flat_map { |i| i["items"] }
                               .select { |i| i["field"] == "Key" }
                               .flat_map do |i|
        [
          { identifier: i["toString"], work_package_id: },
          { identifier: i["fromString"], work_package_id: }
        ]
      end
      aliases = work_package.alias_rows_for_sequence_number(sequence_number)
      aliases.concat(aliases_from_history)
      aliases.uniq!
      work_package.semantic_aliases.upsert_all(aliases,
                                               on_duplicate: :skip,
                                               unique_by: :identifier)

      create_reference!(op_leg: work_package, jira_leg: jira_issue, jira_import: @jira_import, uses_existing: false)
      create_work_package_history(work_package, jira_issue, project)
      work_package
    end
    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

    # rubocop:disable Metrics/AbcSize
    def create_work_package_history(work_package, jira_issue, project)
      journal_service = Import::JiraImportJournals.new(work_package:)

      jira_created_at = jira_issue.payload.dig("fields", "created")
      journal_service.update_creation_entry(date_time: jira_created_at) if jira_created_at.present?

      history = jira_issue.payload.dig("changelog", "histories")
      journal_service.add_history(history:) if history.present?

      comments = jira_issue.payload.dig("fields", "comment", "comments") || []
      comments.each do |comment|
        key = comment.dig("author", "key")
        author = find_user(key)
        create_member(project, author)
        journal_service.add_comment(comment:, user: author || User.system)
      end

      journal_service.call
    end
    # rubocop:enable Metrics/AbcSize

    def create_member(project, member)
      service_call = Members::CreateService
                       .new(user: @system_user, contract_class: EmptyContract)
                       .call(
                         project:,
                         roles: [@project_role],
                         user_id: member.id,
                         principal: member
                       )
      return if service_call.success?

      if service_call.errors.find { |error| error.type == :taken }.blank?
        raise service_call.message
      end
    end

    def find_user(jira_user_key)
      return if jira_user_key.blank?

      jira_user = Import::JiraUser.find_by(origin_id: jira_user_key, jira_import: @jira_import)
      if jira_user
        ref = JiraOpenProjectReference.find_by(
          jira_entity_class: "Import::JiraUser",
          jira_entity_id: jira_user.id
        )
        if ref.present?
          ref.op_leg
        else
          raise "Reference was expected to be found, but it was not. JiraUser: #{jira_user.inspect}"
        end
      else
        raise "Import::JiraUser with jira_user_key #{jira_user_key} not found!"
      end
    end
  end
end
