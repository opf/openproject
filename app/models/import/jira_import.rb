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
  class JiraImport < ApplicationRecord
    include Import::JiraOpenProjectReferenceCreation

    self.table_name = "jira_imports"

    belongs_to :jira, class_name: "Import::Jira"
    belongs_to :author, class_name: "User"

    has_many :transitions,
             class_name: "Import::JiraImportTransition",
             autosave: false,
             dependent: :destroy

    def state_machine
      @state_machine ||= Import::JiraImportStateMachine.new(
        self,
        transition_class: Import::JiraImportTransition,
        association_name: :transitions
      )
    end

    delegate :can_transition_to?,
             :current_state,
             :history,
             :last_transition,
             :last_transition_to,
             :transition_to!,
             :transition_to,
             :in_state?,
             :status_running?,
             :status_equal_or_after?,
             :status_equal_or_before?,
             :status_after?,
             :status_before?,
             :deletable?,
             to: :state_machine

    delegate :client, to: :jira

    def project_ids
      (projects || []).pluck("id")
    end

    # rubocop:disable Metrics/AbcSize
    def destroy_jira_objects
      Import::JiraField.where(jira_import_id: id).destroy_all
      Import::JiraIssue.where(jira_import_id: id).destroy_all
      Import::JiraIssueType.where(jira_import_id: id).destroy_all
      Import::JiraPriority.where(jira_import_id: id).destroy_all
      Import::JiraProject.where(jira_import_id: id).destroy_all
      Import::JiraStatus.where(jira_import_id: id).destroy_all
      Import::JiraUser.where(jira_import_id: id).destroy_all
    end
    # rubocop:enable Metrics/AbcSize

    def import_users
      Import::JiraUser.where(jira_import_id: id).find_each do |jira_user|
        import_user(jira_user)
      end
    end

    private

    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/AbcSize
    def import_user(jira_user)
      user_attrs = jira_user.to_op_attributes
      user_attrs_without_password = user_attrs.except(:password)
      call = Users::CreateService
               .new(user: User.system, contract_class: EmptyContract)
               .call(user_attrs)

      call.on_success do |_result|
        create_reference!(
          op_leg: call.result,
          jira_leg: jira_user,
          jira_import: self,
          uses_existing: false
        )
      end
      call.on_failure do |_result|
        if call.errors.find { |error| error.type == :taken }.present?
          user = jira_user.try_to_find_existing_op_users.first
          if user.present?
            create_reference!(
              op_leg: user,
              jira_leg: jira_user,
              jira_import: self,
              uses_existing: true
            )
          else
            raise "Existing User is expected to be found, because there was an email " \
                  "or login collision. See attributes: #{user_attrs_without_password}"
          end
        else
          raise "Error creating a user (#{user_attrs_without_password}): #{call.message}"
        end
      end

      jira_user_groups = jira_user.payload["groups"]["items"].pluck("name")

      jira_user_groups.each do |group_name|
        call = Groups::CreateService
                 .new(user: User.system, contract_class: EmptyContract)
                 .call(name: group_name)
        call.on_success do |result|
          group = result.result
          create_reference!(
            op_leg: group,
            jira_leg: nil,
            jira_import: self,
            uses_existing: false
          )
        end
        call.on_failure do |_result|
          if call.errors.find { |error| error.type == :taken }.present?
            group = Group.where(name: group_name).first
            if group.present?
              create_reference!(
                op_leg: group,
                jira_leg: nil,
                jira_import: self,
                uses_existing: true
              )
            else
              raise "Existing Group is expected to be found. Group name: #{group_name}"
            end
          else
            raise "Error creating a group #{group_name}: #{call.message}"
          end
        end
        member_id = Import::JiraOpenProjectReference.where(
          jira_import_id: id,
          jira_entity_id: jira_user.id,
          jira_entity_class: jira_user.class.to_s
        ).pick(:op_entity_id)
        group = Group.find_by!(name: group_name)
        Groups::AddUsersService
          .new(group, current_user: User.system)
          .call(ids: [member_id], send_notifications: false)
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/AbcSize
  end
end
