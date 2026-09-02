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
  class JiraRevertImportJob < ApplicationJob
    include JobIteration::Iteration

    REVERT_STEPS = %i[delete_projects
                      delete_types_statuses_and_issue_priorities
                      delete_users
                      delete_groups
                      delete_project_roles
                      delete_custom_fields
                      delete_references
                      delete_jira_objects].freeze

    def text
      "REVERTING"
    end

    def percentage
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      if cursor.present?
        ((REVERT_STEPS.index(cursor.to_sym) + 1) * 100) / REVERT_STEPS.count
      else
        0
      end
    end

    def build_enumerator(jira_import_id, cursor:)
      @jira_import = Import::JiraImport.find(jira_import_id)
      cursor ||= REVERT_STEPS.index(@jira_import.get_job_cursor(self)&.to_sym)
      enumerator_builder.array(REVERT_STEPS, cursor:)
    rescue StandardError => e
      raise if @jira_import.nil?

      @jira_import.transition_to!(:revert_error,
                                  job_id: job_id,
                                  error_backtrace: e.backtrace,
                                  error: e.message)
      nil # JobIteration skips the job when no enumerator is returned
    end

    def each_iteration(revert_step, jira_import_id)
      @jira_import = Import::JiraImport.find(jira_import_id)
      @user = User.system
      ApplicationRecord.transaction do
        send(revert_step)
        @jira_import.set_job_cursor(self, revert_step)
      end
    rescue StandardError => e
      @jira_import.transition_to!(:revert_error,
                                  job_id: job_id,
                                  error_backtrace: e.backtrace,
                                  error: e.message,
                                  revert_step:)
      throw(:abort)
    end

    private

    def delete_projects
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: "Project")
        .find_each do |ref|
          op_leg = ref.op_leg
          service_call = ::Projects::DeleteService.new(user: @user, model: op_leg).call
          raise service_call.message if service_call.failure?
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          next
        end
    end

    def delete_types_statuses_and_issue_priorities
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: ["Type", "IssuePriority", "Status"])
        .find_each do |ref|
          op_leg = ref.op_leg
          op_leg.destroy!
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          next
        end
    end

    def delete_users
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: "User")
        .find_each do |ref|
          op_leg = ref.op_leg
          # EmptyContract is used to make deletion not dependent on Setting.users_deletable_by_admins
          service_call = ::Users::DeleteService.new(user: @user, model: op_leg, contract_class: EmptyContract).call
          raise service_call.message if service_call.failure?
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          next
        end
    end

    def delete_groups
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: "Group")
        .find_each do |ref|
          op_leg = ref.op_leg
          service_call = ::Groups::DeleteService.new(user: @user, model: op_leg).call
          raise service_call.message if service_call.failure?
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          next
        end
    end

    def delete_project_roles
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: "ProjectRole")
        .find_each do |ref|
          op_leg = ref.op_leg
          service_call = ::Roles::DeleteService.new(user: @user, model: op_leg).call
          raise service_call.message if service_call.failure?
        rescue Import::JiraOpenProjectReference::LegNotFoundError
          next
        end
    end

    def delete_custom_fields
      Import::JiraOpenProjectReference
        .where(jira_import_id: @jira_import.id, uses_existing: false)
        .where(op_entity_class: "WorkPackageCustomField")
        .find_each do |ref|
          op_leg = ref.op_leg
          op_leg.destroy!
        rescue Import::JiraOpenProjectReference::LegNotFoundError
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
