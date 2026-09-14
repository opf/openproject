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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Import
  class JiraCreateUsersJob < ProgressableJob
    include JiraOpenProjectReferenceCreation

    def text
      "Create users"
    end

    def percentage
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      if cursor.present?
        total = Import::JiraUser.where(jira_import:).count
        position = Import::JiraUser.where(id: ..cursor, jira_import:).count
        (position.to_f / total * 100).round(2)
      else
        0
      end
    end

    def build_enumerator(jira_import_id, cursor:)
      @jira_import = Import::JiraImport.find(jira_import_id)

      cursor ||= @jira_import.get_job_cursor(self)
      enumerator_builder.active_record_on_records(
        Import::JiraUser.where(jira_import_id:),
        cursor: cursor
      )
    end

    def each_iteration(jira_user, _jira_import_id)
      Journal::NotificationConfiguration.with(false) do
        Journal::EventConfiguration.with(false) do
          import_user(jira_user)
          @jira_import.set_job_cursor(self, jira_user.id)
        end
      end
    end

    private

    def import_user(jira_user)
      # A retried run re-processes every Jira user. Without this the OP user created by the
      # previous attempt is seen as a login/email collision and a duplicate is created.
      already_imported = Import::JiraOpenProjectReference.exists?(
        jira_import_id: @jira_import.id,
        jira_entity_class: Import::JiraUser.to_s,
        jira_entity_id: jira_user.id
      )
      return import_user_groups(jira_user) if already_imported

      user_attrs = jira_user.to_op_attributes
      call = Users::CreateService
               .new(user: User.system, contract_class: EmptyContract)
               .call(user_attrs)

      call.on_success do |_result|
        create_reference!(
          op_leg: call.result,
          jira_leg: jira_user,
          jira_import: @jira_import,
          uses_existing: false
        )
      end
      call.on_failure do |_result|
        handle_create_user_failure(call, user_attrs, jira_user)
      end

      import_user_groups(jira_user)
    end

    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    def handle_create_user_failure(call, user_attrs, jira_user)
      taken_errors = call.errors.select { |error| error.type == :taken }

      if taken_errors.any? { |e| e.attribute == :mail }
        user = jira_user.try_to_find_existing_op_user_by_mail
        if user.blank?
          raise "Existing User is expected to be found, because there was an email " \
                "collision. See attributes: #{user_attrs.except(:password)}"
        end

        if jira_user_already_referenced?(user)
          handle_referenced_user_mail_conflict(user_attrs, jira_user)
        else
          create_reference!(op_leg: user, jira_leg: jira_user, jira_import: @jira_import, uses_existing: true)
        end
        return
      end

      if taken_errors.any? { |e| e.attribute == :login }
        handle_referenced_user_login_conflict(user_attrs, jira_user)
        return
      end

      raise "Error creating a user (#{user_attrs.except(:password)}): #{call.message}"
    end
    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

    # rubocop:disable Metrics/AbcSize
    def handle_referenced_user_mail_conflict(user_attrs, jira_user)
      unique_mail, reusable_user = resolve_jira_email(user_attrs[:mail], jira_user.origin_id)
      if reusable_user
        create_reference!(
          op_leg: reusable_user,
          jira_leg: jira_user,
          jira_import: @jira_import,
          uses_existing: true
        )
      else
        overrides = {
          mail: unique_mail,
          login: resolve_jira_login(user_attrs[:login], jira_user.origin_id)
        }

        new_call = Users::CreateService
         .new(user: User.system, contract_class: EmptyContract)
         .call(user_attrs.merge(overrides))
        unless new_call.success?
          raise "Error creating a user with modified email '#{unique_mail}' " \
                "(#{user_attrs.except(:password)}): #{new_call.message}"
        end

        create_reference!(
          op_leg: new_call.result,
          jira_leg: jira_user,
          jira_import: @jira_import,
          uses_existing: false
        )
      end
    end
    # rubocop:enable Metrics/AbcSize

    def handle_referenced_user_login_conflict(user_attrs, jira_user)
      unique_login = resolve_jira_login(user_attrs[:login], jira_user.origin_id)
      new_call = Users::CreateService
                   .new(user: User.system, contract_class: EmptyContract)
                   .call(user_attrs.merge(login: unique_login))
      unless new_call.success?
        raise "Error creating a user with modified login '#{unique_login}' " \
              "(#{user_attrs.except(:password)}): #{new_call.message}"
      end

      create_reference!(
        op_leg: new_call.result,
        jira_leg: jira_user,
        jira_import: @jira_import,
        uses_existing: false
      )
    end

    def import_user_groups(jira_user)
      jira_user.payload["groups"]["items"].pluck("name").each do |group_name|
        import_user_group(group_name, jira_user)
      end
    end

    # rubocop:disable Metrics/AbcSize
    def import_user_group(group_name, jira_user)
      call = Groups::CreateService
               .new(user: User.system, contract_class: EmptyContract)
               .call(name: group_name)
      call.on_success do |result|
        create_reference!(
          op_leg: result.result,
          jira_leg: nil,
          jira_import: @jira_import,
          uses_existing: false
        )
      end
      call.on_failure do |_result|
        handle_create_group_failure(call, group_name)
      end
      member_id = Import::JiraOpenProjectReference.where(
        jira_import_id: @jira_import.id,
        jira_entity_id: jira_user.id,
        jira_entity_class: jira_user.class.to_s
      ).pick(:op_entity_id)
      group = Group.find_by!(name: group_name)
      Groups::AddUsersService
        .new(group, current_user: User.system)
        .call(ids: [member_id], send_notifications: false)
    end
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/AbcSize
    def handle_create_group_failure(call, group_name)
      if call.errors.find { |error| error.type == :taken }.blank?
        raise "Error creating a group #{group_name}: #{call.message}"
      end

      group = Group.where(name: group_name).first
      if group.present?
        # The group is imported once per member. Overwriting the reference would clear
        # uses_existing and make the revert skip a group this run created.
        already_referenced = Import::JiraOpenProjectReference.exists?(
          jira_import_id: @jira_import.id,
          op_entity_class: group.class.to_s,
          op_entity_id: group.id
        )
        return if already_referenced

        create_reference!(
          op_leg: group,
          jira_leg: nil,
          jira_import: @jira_import,
          uses_existing: true
        )
      else
        raise "Existing Group is expected to be found. Group name: #{group_name}"
      end
    end
    # rubocop:enable Metrics/AbcSize

    def jira_user_already_referenced?(op_user)
      Import::JiraOpenProjectReference.exists?(
        jira_import_id: @jira_import.id,
        jira_entity_class: Import::JiraUser.to_s,
        op_entity_id: op_user.id,
        op_entity_class: op_user.class.to_s
      )
    end

    # Returns [email, existing_user_or_nil].
    # existing_user_or_nil is set when a user already exists at that address and has no
    # JiraUser reference yet - meaning it can be reused instead of creating a new account.
    def resolve_jira_email(original_email, jira_user_key)
      local, domain = original_email.split("@", 2)
      safe_key = jira_user_key.gsub(/[^a-zA-Z0-9._-]/, "_")

      candidate = "#{local}+#{safe_key}@#{domain}"
      user = User.find_by(["LOWER(mail) = ?", candidate.downcase])
      return [candidate, user] unless user && jira_user_already_referenced?(user)

      counter = 1
      loop do
        candidate = "#{local}+#{safe_key}+#{counter}@#{domain}"
        user = User.find_by(["LOWER(mail) = ?", candidate.downcase])
        break [candidate, user] unless user && jira_user_already_referenced?(user)

        counter += 1
      end
    end

    def resolve_jira_login(original_login, jira_user_key)
      safe_key = jira_user_key.gsub(/[^a-zA-Z0-9._-]/, "_")

      candidate = "#{original_login}+#{safe_key}"
      return candidate unless User.by_login(candidate).exists?

      counter = 1
      loop do
        candidate = "#{original_login}+#{safe_key}+#{counter}"
        break candidate unless User.by_login(candidate).exists?

        counter += 1
      end
    end
  end
end
