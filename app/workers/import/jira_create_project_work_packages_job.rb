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
  class JiraCreateProjectWorkPackagesJob < ProgressableJob
    include Import::JiraOpenProjectReferenceCreation
    include ::Import::JiraCreateProjectJob::JiraImportCustomFields
    include Import::JiraJobUtils
    include Import::JiraProjectIssuesJob

    on_complete do
      # Update project.wp_sequence_counter to max sequence_number found in migrated from jira work_packages
      # or 0 in case there are no work_packages in the project.
      Project
        .where(id: @project.id)
        .update_all(["wp_sequence_counter = (SELECT COALESCE(MAX(sequence_number), 0) " \
                     "FROM work_packages WHERE project_id = ?)", @project.id])
      tagged_log("jira_import_id:#{arguments[0]}",
                 "jira_project_id:#{jira_project_key(arguments[1])}", "jira_object_type:project") do
        Rails.logger.debug "Creating work packages finished"
      end
    end

    def text
      jira_project_name = Import::JiraProject.find(arguments[1]).payload["name"]
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title", jira_project_name:)
    end

    # rubocop:disable-next Metrics/AbcSize
    def build_enumerator(jira_import_id, jira_project_id, cursor:)
      jira_project = jira_project(jira_project_id)
      tagged_log("jira_import_id:#{jira_import_id}",
                 "jira_project_id:#{jira_project.payload['key']}",
                 "jira_object_type:project") do
        Rails.logger.debug "Creating work packages started"
        @jira_import = Import::JiraImport.find(jira_import_id)
        jira = @jira_import.jira
        @jira_id = jira.id
        @system_user = User.system
        @jira_client = jira.client

        @project_role = Role.find_by!(name: "JiraMember")
        @custom_field_registry = build_custom_field_registry

        @project = JiraOpenProjectReference.find_by!(
          jira_entity_id: jira_project.id,
          jira_entity_class: jira_project.class.to_s
        ).op_leg

        setup_resolution_date_cf(jira_project)

        cursor ||= @jira_import.get_job_cursor(self)
        enumerator_builder.active_record_on_records(
          Import::JiraIssue.where(jira_import_id:, jira_project_id:),
          cursor: cursor
        )
      end
    end

    # rubocop:disable-next Metrics/AbcSize
    def each_iteration(jira_issue, _jira_import_id, _jira_project_id)
      jira_issue_key = jira_issue.payload["key"]
      tagged_log("jira_import_id:#{_jira_import_id}",
                 "jira_project_id:#{jira_project_key(_jira_project_id)}",
                 "jira_issue_key:#{jira_issue_key}") do
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
    end

    private

    def new_custom_fields_in_type(jira_issue, type, custom_field_registry)
      custom_fields = custom_fields_for_issue(custom_field_registry, jira_issue)
      custom_fields << @resolution_date_cf if @resolution_date_cf

      existing_cf_ids = type.default_variant.custom_field_ids
      custom_fields.reject { |cf| existing_cf_ids.include?(cf.id) }
    end

    def update_custom_fields_in_type(type, new_custom_fields)
      variant = type.default_variant
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

    def create_type(jira_issue, project)
      issue_type = jira_issue.payload["fields"]["issuetype"]
      name = issue_type["name"]
      type, uses_existing = find_or_create_resource(Type, name, jira_object_type: "issueType") { create_new_type(name) }

      enable_type(project, type)
      jira_issue_type = Import::JiraIssueType.find_by!(origin_id: issue_type["id"], jira_import_id: @jira_import.id)
      create_reference!(op_leg: type, jira_leg: jira_issue_type, jira_import: @jira_import, uses_existing:)
      type
    end

    def create_new_type(name)
      service_call = WorkPackageTypes::CreateService
                       .new(user: @system_user)
                       .call(name:)
      raise service_call.message unless service_call.success?

      service_call.result
    end

    def enable_type(project, type)
      service_call = Projects::Types::AddService
                       .new(user: @system_user, model: project)
                       .call(variant: type.default_variant)
      if service_call.failure?
        Rails.logger.error service_call.message
        raise service_call.message
      end
    end

    def create_status(jira_issue)
      issue_status = jira_issue.payload["fields"]["status"]
      resolution = @jira_import.exclude_resolution_fields? ? nil : jira_issue.payload["fields"]["resolution"]
      name = status_name(issue_status, resolution)
      status, uses_existing = find_or_create_resource(Status, name, jira_object_type: "status") do
        is_closed = issue_status.dig("statusCategory", "key") == "done"
        Status.create!(name:, is_closed:)
      end

      jira_status = Import::JiraStatus.find_by!(origin_id: issue_status["id"], jira_import_id: @jira_import.id)
      create_reference!(op_leg: status, jira_leg: jira_status, jira_import: @jira_import, uses_existing:)
      status
    end

    def status_name(issue_status, resolution)
      return issue_status["name"] if resolution.blank?

      "#{issue_status['name']} - #{resolution['name']}"
    end

    def create_priority(jira_issue)
      issue_priority = jira_issue.payload["fields"]["priority"]
      return if issue_priority.blank?

      name = issue_priority["name"]
      priority, uses_existing = find_or_create_resource(IssuePriority, name, jira_object_type: "priority") do
        IssuePriority.create!(name:)
      end
      jira_priority = Import::JiraPriority.find_by!(origin_id: issue_priority["id"], jira_import_id: @jira_import.id)
      create_reference!(op_leg: priority, jira_leg: jira_priority, jira_import: @jira_import, uses_existing:)
      priority
    end

    def find_or_create_resource(klass, name, jira_object_type:)
      Rails.logger.tagged("jira_object_type:#{jira_object_type}", "jira_object_id_or_name:#{name}") do
        resource = find_resource(klass, name)
        if resource
          Rails.logger.debug { "Found existing #{klass.name}" }
          return [resource, true]
        end

        lock_key = "jira_import_create_#{klass.name.underscore}_#{name.parameterize(separator: '_')}"
        OpenProject::Mutex.with_advisory_lock(klass, lock_key, transaction: true) do
          resource = find_resource(klass, name)
          if resource
            Rails.logger.debug { "Found existing #{klass.name}" }
            next [resource, true]
          end

          Rails.logger.debug { "Creating #{klass.name}" }
          [yield, false]
        end
      end
    end

    def find_resource(klass, name)
      klass.find_by("LOWER(name) = LOWER(?)", name)
    end

    def setup_resolution_date_cf(jira_project)
      return if @jira_import.exclude_resolution_fields?

      custom_field = system_field_custom_field("resolutiondate")
      return unless custom_field
      return unless has_issues_with_resolution_date?(jira_project)

      @resolution_date_cf = custom_field
    end

    def has_issues_with_resolution_date?(jira_project)
      Import::JiraIssue
        .where(jira_import_id: @jira_import.id, jira_project_id: jira_project.id)
        .with_field_set("resolutiondate")
        .exists?
    end

    def resolution_date_cf_attrs(jira_issue)
      return {} unless @resolution_date_cf

      raw = jira_issue.payload.dig("fields", "resolutiondate")
      return {} if raw.blank?

      { @resolution_date_cf.attribute_getter => Time.zone.parse(raw).iso8601 }
    end

    def label_attrs(jira_issue)
      issue_labels = jira_label_names(jira_issue).index_with { find_label(it) }
      log_missing_labels(issue_labels)

      label_ids = issue_labels.values.compact.map(&:id)
      label_ids.any? ? { label_ids: } : {}
    end

    def jira_label_names(jira_issue)
      labels = jira_issue.payload.dig("fields", "labels")
      return [] unless labels.is_a?(Array)

      labels.filter_map { it.to_s.squish.presence }
    end

    def log_missing_labels(issue_labels)
      missing = issue_labels.filter_map { |name, label| name if label.nil? }
      return if missing.empty?

      Rails.logger.warn("Skipping jira labels without an OpenProject label: #{missing.join(', ')}")
    end

    def find_label(name) = labels_by_name[name.downcase]

    def labels_by_name
      @labels_by_name ||= Hash.new { |cache, name| cache[name] = Label.named(name).first }
    end

    def update_workflows(type)
      Rails.logger.tagged("jira_object_type:issueType", "jira_object_id_or_name:#{type.name}") do
        statuses = Status.all
        row = statuses.to_h { |status| [status.id.to_s, ["always"]] }
        status_params = statuses.to_h { |status| [status.id.to_s, row] }
        call = Workflows::BulkUpdateService
                  .new(role: @project_role, workflow: type.default_variant.workflow, tab: "always")
                  .call(status_params)
        if call.failure?
          Rails.logger.error call.message
          raise call.message
        end
      end
    end

    # rubocop:disable-next Metrics/AbcSize, Metrics/PerceivedComplexity
    def create_work_package(jira_issue, project, type, status, priority, custom_field_registry)
      Rails.logger.debug "Creating work package"

      # required because otherwise project.types does not include type and then wp creation fails.
      project.reload

      due_date = jira_issue.payload.dig("fields", "duedate")&.to_date
      author_key = jira_issue.payload.dig("fields", "creator", "key")
      author = find_user(author_key)
      assignee_key = jira_issue.payload.dig("fields", "assignee", "key")
      assigned_to = find_user(assignee_key)
      [author, assigned_to].uniq.compact.each { |member| create_member(project, member) }

      custom_field_attrs = collect_custom_field_attributes(custom_field_registry, jira_issue)
                             .merge(resolution_date_cf_attrs(jira_issue))

      original_estimate_seconds = jira_issue.payload.dig("fields", "timetracking", "originalEstimateSeconds")
      remaining_estimate_seconds = jira_issue.payload.dig("fields", "timetracking", "remainingEstimateSeconds")

      # fixVersions and versions can be hidden in Jira Field Configuration
      # then they are absent in the API payload as well
      target_versions =
        jira_issue
          .payload["fields"]["fixVersions"]
          &.map { |v| v.fetch("id") }
          .then do |origin_ids|
            Import::JiraVersion
              .where(jira_import: @jira_import, origin_id: origin_ids)
              .filter_map { |jira_version| @jira_import.find_op_leg(jira_version) }
          end
      observed_in_versions =
        jira_issue.payload["fields"]["versions"]
          &.map { |v| v.fetch("id") }
          .then do |origin_ids|
            Import::JiraVersion
              .where(jira_import: @jira_import, origin_id: origin_ids)
              .filter_map { |jira_version| @jira_import.find_op_leg(jira_version) }
          end

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
            target_versions:,
            observed_in_versions:,
            due_date:,
            # Otherwise SetAttributesService moves the due date to the next working day.
            ignore_non_working_days: due_on_non_working_day?(due_date),
            estimated_hours: (original_estimate_seconds / 3600.0 if original_estimate_seconds),
            remaining_hours: (remaining_estimate_seconds / 3600.0 if remaining_estimate_seconds),
            skip_semantic_id_allocation: true,
            **label_attrs(jira_issue),
            **custom_field_attrs
          )
      unless service_call.success?
        Rails.logger.error service_call.message
        raise service_call.message
      end

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

    def due_on_non_working_day?(due_date)
      due_date.present? && working_days.non_working?(due_date)
    end

    def working_days
      @working_days ||= WorkPackages::Shared::WorkingDays.new
    end

    # rubocop:disable-next Metrics/AbcSize
    def create_work_package_history(work_package, jira_issue, project)
      journal_service = Import::JiraImportJournals.new(work_package:)

      jira_created_at = jira_issue.payload.dig("fields", "created")
      journal_service.set_creation_time(date_time: jira_created_at)

      history = jira_issue.payload.dig("changelog", "histories")
      journal_service.add_history(history:) if history.present?

      comments = jira_issue.payload.dig("fields", "comment", "comments") || []
      comments.each do |comment|
        Rails.logger.tagged("jira_object_type:comment", "jira_object_id_or_name:#{comment['created']}") do
          Rails.logger.debug "Adding comment"
          key = comment.dig("author", "key")
          Rails.logger.tagged("author:#{key}") do
            author = find_user(key)
            create_member(project, author)
            journal_service.add_comment(comment:, user: author || User.system)
          end
        end
      end

      journal_service.call(updated_at: jira_issue.payload.dig("fields", "updated"))
    end

    def find_user(jira_user_key)
      return if jira_user_key.blank?

      Rails.logger.tagged("jira_object_type:user", "jira_object_id_or_name:#{jira_user_key}") do
        jira_user = Import::JiraUser.find_by(origin_id: jira_user_key, jira_import: @jira_import)
        if jira_user
          ref = JiraOpenProjectReference.find_by(
            jira_entity_class: "Import::JiraUser",
            jira_entity_id: jira_user.id
          )
          if ref.present?
            ref.op_leg
          else
            log_message = "Reference was expected to be found, but it was not. JiraUser: #{jira_user.inspect}"
            Rails.logger.error log_message
            raise log_message
          end
        else
          Rails.logger.warn "Import::JiraUser with jira_user_key #{jira_user_key} not found! Using DeletedUser instead."
          DeletedUser.first
        end
      end
    end
  end
end
