# frozen_string_literal: true

require "net/ldap"
require "net/ldap/dn"

module LdapDepartments
  # Maps a single LDAP organizational unit (by DN, optionally keyed by a stable GUID) onto an
  # OpenProject department (a Group with organizational_unit: true).
  class SynchronizedDepartment < ApplicationRecord
    belongs_to :synchronized_tree,
               class_name: "::LdapDepartments::SynchronizedTree"

    belongs_to :ldap_auth_source

    belongs_to :group

    # Dropping the mapping only removes the tracking records, not the actual group memberships.
    has_many :users,
             class_name: "::LdapDepartments::Membership",
             inverse_of: :synchronized_department,
             dependent: :delete_all

    validates :dn, presence: true
    validates :group, presence: true
    validates :ldap_auth_source, presence: true

    ##
    # Add a set of users to this department, recording the sync membership and moving them into the
    # underlying group. Callers must ensure the users are not members of another department.
    #
    # @param new_users [Array<User> | Array<Integer>]
    def add_members!(new_users)
      return if new_users.empty?

      self.class.transaction do
        memberships = new_users.to_a.map { |user| { synchronized_department_id: id, user_id: user_id(user) } }
        ::LdapDepartments::Membership.insert_all memberships, unique_by: %i[user_id synchronized_department_id]

        add_members_to_group(new_users)
      end
    end

    ##
    # Remove a set of users from this department and drop their sync membership.
    #
    # @param users_to_remove [Array<User> | Array<Integer>]
    def remove_members!(users_to_remove)
      return if users_to_remove.empty?

      user_ids = users_to_remove.map { |user| user_id(user) }

      self.class.transaction do
        users.delete users.where(user_id: user_ids).select(:id)
        remove_members_from_group(user_ids)
      end
    end

    private

    def user_id(user)
      case user
      when Integer
        user
      when User
        user.id
      else
        raise ArgumentError, "Expected User or User ID (Integer) but got #{user}"
      end
    end

    # rubocop:disable Metrics/AbcSize
    def add_members_to_group(new_users)
      user_ids = new_users.map { |user| user_id(user) }

      call = Groups::UpdateService
        .new(user: User.system, model: group, contract_class: Groups::SyncUpdateContract)
        .call(add_user_ids: user_ids)

      call.on_success do
        Rails.logger.debug { "[LDAP departments] Added users #{user_ids} to #{group.name}" }
      end

      call.on_failure do
        Rails.logger.error "[LDAP departments] Failed to add users #{user_ids} to #{group.name}: #{call.message}"
        raise ActiveRecord::Rollback
      end
    end

    def remove_members_from_group(user_ids)
      call = Groups::UpdateService
        .new(user: User.system, model: group, contract_class: Groups::SyncUpdateContract)
        .call(remove_user_ids: user_ids)

      call.on_success do
        Rails.logger.debug { "[LDAP departments] Removed users #{user_ids} from #{group.name}" }
      end

      call.on_failure do
        Rails.logger.error "[LDAP departments] Failed to remove users #{user_ids} from #{group.name}: #{call.message}"
        raise ActiveRecord::Rollback
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
