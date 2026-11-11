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
  class JiraRevertImportJob < ApplicationJob
    include JobIteration::Iteration
    include JiraJobUtils

    REVERT_STEPS = %i[delete_projects
                      delete_types_statuses_and_issue_priorities
                      delete_users
                      delete_groups
                      delete_project_roles
                      delete_custom_fields
                      delete_labels
                      delete_references
                      delete_jira_objects].freeze

    # Maps the op_entity_class values delete_types_statuses_and_issue_priorities handles to their
    # jira_object_type tag. Group and ProjectRole are tagged directly in their own delete_* method
    # since each only ever deletes that one class.
    REF_OBJECT_TYPES = {
      "Type" => "issueType",
      "IssuePriority" => "priority",
      "Status" => "status"
    }.freeze

    WORK_PACKAGE_ASSOCIATIONS = {
      "Type" => :type,
      "IssuePriority" => :priority,
      "Status" => :status
    }.freeze

    def text
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title")
    end

    def progress
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      if cursor.present?
        total = REVERT_STEPS.count
        current = REVERT_STEPS.index(cursor.to_sym) + 1
        percentage = (current.to_f / total * 100).round(2)
        { current:, total:, percentage: }
      else
        { current: 0, total: REVERT_STEPS.count, percentage: 0 }
      end
    end

    def build_enumerator(jira_import_id, cursor:)
      @jira_import = Import::JiraImport.find(jira_import_id)
      cursor ||= REVERT_STEPS.index(@jira_import.get_job_cursor(self)&.to_sym)
      enumerator_builder.array(REVERT_STEPS, cursor:)
    rescue StandardError => e
      raise if @jira_import.nil?

      tagged_log("jira_import_id:#{jira_import_id}") do
        Rails.logger.error "Building revert enumerator failed: #{e.message}"
      end
      @jira_import.transition_to!(:revert_error,
                                  job_id: job_id,
                                  error_backtrace: e.backtrace,
                                  error: e.message)
      nil # JobIteration skips the job when no enumerator is returned
    end

    # rubocop:disable-next Metrics/AbcSize
    def each_iteration(revert_step, jira_import_id)
      @jira_import = Import::JiraImport.find(jira_import_id)
      @user = User.system
      tagged_log("jira_import_id:#{jira_import_id}") do
        Rails.logger.info "Revert step '#{revert_step}' started"
        ApplicationRecord.transaction do
          send(revert_step)
          @jira_import.set_job_cursor(self, revert_step)
        end
        Rails.logger.info "Revert step '#{revert_step}' finished"
      end
    rescue StandardError => e
      tagged_log("jira_import_id:#{jira_import_id}") do
        Rails.logger.error "Revert step '#{revert_step}' failed: #{e.message}"
      end
      @jira_import.transition_to!(:revert_error,
                                  job_id: job_id,
                                  error_backtrace: e.backtrace,
                                  error: e.message,
                                  revert_step:)
      throw(:abort)
    end

    private

    # rubocop:disable-next Metrics/AbcSize
    def delete_projects
      hand_over_sprints_reused_by_other_imports
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: "Project")
        .find_each do |ref|
          Rails.logger.tagged("jira_object_type:project", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.debug "Deleting project"
            op_leg = ref.op_leg
            service_call = ::Projects::DeleteService.new(user: @user, model: op_leg).call
            if service_call.failure?
              Rails.logger.error service_call.message
              raise service_call.message
            end
          end
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          Rails.logger.tagged("jira_object_type:project", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.warn "OpenProject project no longer exists, skipping its deletion"
          end
          next
        end
    end

    # Deleting the owning project would destroy the sprint and unassign it from the work packages of the
    # imports that reused it, so it moves to the project that keeps most of its work packages.
    def hand_over_sprints_reused_by_other_imports
      reverted_project_ids = created_project_ids
      Sprint.where(id: sprint_ids_reused_by_other_imports, project_id: reverted_project_ids).find_each do |sprint|
        new_owner = remaining_owner(sprint, reverted_project_ids)
        next if new_owner.nil?

        Rails.logger.tagged("jira_object_type:sprint", "jira_object_id_or_name:#{sprint.id}") do
          Rails.logger.info "Moving sprint to project #{new_owner.identifier}, another import still uses it"
        end
        keep_active_sprint_valid(sprint, new_owner)
        sprint.update!(project: new_owner)
      end
    end

    def created_project_ids
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false, op_entity_class: "Project")
        .pluck(:op_entity_id)
        .map(&:to_i)
    end

    def sprint_ids_reused_by_other_imports
      own_sprint_ids = Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, op_entity_class: "Sprint")
        .select(:op_entity_id)
      Import::JiraOpenProjectReference
        .where(op_entity_class: "Sprint", op_entity_id: own_sprint_ids)
        .where.not(jira_import_id: @jira_import.id)
        .distinct
        .pluck(:op_entity_id)
        .map(&:to_i)
    end

    def remaining_owner(sprint, reverted_project_ids)
      project_id = sprint.work_packages
                         .where.not(project_id: reverted_project_ids)
                         .group(:project_id)
                         .order(Arel.sql("COUNT(*) DESC"), :project_id)
                         .pick(:project_id)
      Project.find_by(id: project_id)
    end

    def keep_active_sprint_valid(sprint, project)
      return if !sprint.active? || project.allow_multiple_active_sprints?
      return unless Sprint.for_project(project).active.where.not(id: sprint.id).exists?

      project.update!(allow_multiple_active_sprints: true)
    end

    # rubocop:disable-next Metrics/AbcSize
    def delete_types_statuses_and_issue_priorities
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: ["Type", "IssuePriority", "Status"])
        .find_each do |ref|
          op_leg = ref.op_leg

          # delete_projects runs first, so any work package left is from outside this import
          next if WorkPackage.exists?(WORK_PACKAGE_ASSOCIATIONS.fetch(ref.op_entity_class) => op_leg)

          Rails.logger.tagged("jira_object_type:#{REF_OBJECT_TYPES.fetch(ref.op_entity_class)}",
                              "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.debug { "Deleting #{ref.op_entity_class}" }
            op_leg.destroy!
          end
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          Rails.logger.tagged("jira_object_type:#{REF_OBJECT_TYPES.fetch(ref.op_entity_class)}",
                              "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.warn "OpenProject #{ref.op_entity_class} no longer exists, skipping its deletion"
          end
          next
        end
    end

    # rubocop:disable-next Metrics/AbcSize
    def delete_users
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: "User")
        .find_each do |ref|
          Rails.logger.tagged("jira_object_type:user", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.debug "Deleting user"
            op_leg = ref.op_leg
            # EmptyContract is used to make deletion not dependent on Setting.users_deletable_by_admins
            service_call = ::Users::DeleteService.new(user: @user, model: op_leg, contract_class: EmptyContract).call
            if service_call.failure?
              Rails.logger.error service_call.message
              raise service_call.message
            end
          end
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          Rails.logger.tagged("jira_object_type:user", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.warn "OpenProject user no longer exists, skipping its deletion"
          end
          next
        end
    end

    # rubocop:disable-next Metrics/AbcSize
    def delete_groups
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: "Group")
        .find_each do |ref|
          Rails.logger.tagged("jira_object_type:group", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.debug "Deleting group"
            op_leg = ref.op_leg
            service_call = ::Groups::DeleteService.new(user: @user, model: op_leg).call
            if service_call.failure?
              Rails.logger.error service_call.message
              raise service_call.message
            end
          end
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          Rails.logger.tagged("jira_object_type:group", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.warn "OpenProject group no longer exists, skipping its deletion"
          end
          next
        end
    end

    # rubocop:disable-next Metrics/AbcSize
    def delete_project_roles
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: "ProjectRole")
        .find_each do |ref|
          Rails.logger.tagged("jira_object_type:projectRole", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.debug "Deleting project role"
            op_leg = ref.op_leg
            service_call = ::Roles::DeleteService.new(user: @user, model: op_leg).call
            if service_call.failure?
              Rails.logger.error service_call.message
              raise service_call.message
            end
          end
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          Rails.logger.tagged("jira_object_type:projectRole", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.warn "OpenProject project role no longer exists, skipping its deletion"
          end
          next
        end
    end

    def delete_custom_fields
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: "WorkPackageCustomField")
        .find_each do |ref|
          Rails.logger.tagged("jira_object_type:customField", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.debug "Deleting custom field"
            op_leg = ref.op_leg
            op_leg.destroy!
          end
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          Rails.logger.tagged("jira_object_type:customField", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.warn "OpenProject custom field no longer exists, skipping its deletion"
          end
          next
        end
    end

    # rubocop:disable-next Metrics/AbcSize
    def delete_labels
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: "Label")
        .find_each do |ref|
          op_leg = ref.op_leg
          # label is used by something outside this import run, keep it
          next if op_leg.labelings.exists?

          Rails.logger.tagged("jira_object_type:label", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.debug "Deleting label"
            service_call = ::Labels::DeleteService.new(user: @user, model: op_leg).call
            if service_call.failure?
              Rails.logger.error service_call.message
              raise service_call.message
            end
          end
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          Rails.logger.tagged("jira_object_type:label", "jira_object_id_or_name:#{ref.op_entity_id}") do
            Rails.logger.warn "OpenProject label no longer exists, skipping its deletion"
          end
          next
        end
    end

    def delete_references
      Import::JiraOpenProjectReference.where(jira_import_id: @jira_import.id).delete_all
    end

    def delete_jira_objects
      @jira_import.destroy_jira_objects
      @jira_import.transition_to!(:reverted, job_id: job_id)
    end
  end
end
