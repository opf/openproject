# frozen_string_literal: true

require "net/ldap"

module LdapDepartments
  # Assigns the users found below a tree's base DN to the department of their immediate parent OU.
  # LDAP is authoritative: a user is moved out of any other department first, and memberships the
  # sync no longer sees are removed.
  class SynchronizeMembersService
    attr_reader :tree, :ldap

    def initialize(tree)
      @tree = tree
      @ldap = tree.ldap_auth_source
    end

    def call
      synchronize!
      ServiceResult.success
    rescue StandardError => e
      message = "[LDAP departments] Failed to synchronize members of tree '#{tree.name}': #{e.class}: #{e.message}"
      Rails.logger.error(message)
      ServiceResult.failure(message:)
    end

    def synchronize!
      department_by_dn = build_department_index
      return if department_by_dn.empty?

      desired = collect_desired_memberships(department_by_dn)
      apply(department_by_dn.values.uniq, desired)
    end

    private

    def build_department_index
      SynchronizedDepartment
        .where(synchronized_tree_id: tree.id)
        .index_by { |sync| Dn.normalize(sync.dn) }
    end

    # Returns a hash of synchronized_department_id => Set(user_id) reflecting the LDAP state.
    def collect_desired_memberships(department_by_dn)
      login_data = {}
      login_department = {}

      search_users do |entry|
        department = department_for(entry, department_by_dn)
        next unless department

        data = ldap.get_user_attributes_from_ldap_entry(entry)
        login = data[:login]
        next if login.blank?

        login_data[login] = data.except(:dn)
        login_department[login] = department
      end

      create_missing!(login_data) if tree.sync_users
      build_desired(login_data, login_department)
    end

    def department_for(entry, department_by_dn)
      parent = Dn.parent(entry.dn)
      return nil if parent.nil?

      department_by_dn[Dn.normalize(parent)]
    end

    def build_desired(login_data, login_department)
      ids_by_login = user_ids_by_login(login_data.keys)

      desired = Hash.new { |hash, key| hash[key] = Set.new }
      login_department.each do |login, department|
        user_id = ids_by_login[login.downcase]
        desired[department.id] << user_id if user_id
      end
      desired
    end

    def user_ids_by_login(logins)
      User
        .where("LOWER(login) IN (?)", logins.map(&:downcase))
        .pluck(:login, :id)
        .to_h { |login, id| [login.downcase, id] }
    end

    def search_users(&)
      ldap.with_connection do |connection|
        connection.search(base: tree.base_dn,
                          filter: tree.parsed_user_filter,
                          attributes: ldap.search_attributes,
                          &)
      end
    end

    # Two passes: remove everything no longer desired first, so a user moving between departments of
    # the same tree is freed before being added to the new one.
    def apply(departments, desired)
      departments.each do |department|
        remove_outdated(department, desired[department.id])
        add_new(department, desired[department.id])
        SynchronizedDepartment.reset_counters(department.id, :users, touch: true)
      end
    end

    def remove_outdated(department, desired_ids)
      current = current_member_ids(department)
      to_remove = current - desired_ids
      department.remove_members!(to_remove.to_a) if to_remove.any?
    end

    def add_new(department, desired_ids)
      to_add = desired_ids - current_member_ids(department)
      return if to_add.empty?

      relocate_from_other_departments(to_add.to_a, department.group_id)
      department.add_members!(to_add.to_a)
    end

    def current_member_ids(department)
      Membership.where(synchronized_department_id: department.id).pluck(:user_id).to_set
    end

    # LDAP places each user in exactly one OU, so remove them from any other department first.
    def relocate_from_other_departments(user_ids, keep_group_id)
      GroupUser
        .joins(:group)
        .merge(Group.organizational_units)
        .where(user_id: user_ids)
        .where.not(group_id: keep_group_id)
        .pluck(:group_id, :user_id)
        .group_by(&:first)
        .each { |group_id, rows| remove_from_group(group_id, rows.map(&:last)) }
    end

    def remove_from_group(group_id, user_ids)
      group = Group.find_by(id: group_id)
      return unless group

      call = Groups::UpdateService
        .new(user: User.system, model: group, contract_class: Groups::SyncUpdateContract)
        .call(remove_user_ids: user_ids)
      Rails.logger.error("[LDAP departments] Failed to relocate users from #{group.name}: #{call.message}") unless call.success?

      drop_memberships_for_group(group_id, user_ids)
    end

    def drop_memberships_for_group(group_id, user_ids)
      SynchronizedDepartment.where(group_id:).find_each do |sync|
        sync.users.where(user_id: user_ids).delete_all
        SynchronizedDepartment.reset_counters(sync.id, :users, touch: true)
      end
    end

    def create_missing!(login_data)
      existing = User.where(login: login_data.keys).pluck(:login).to_set(&:downcase)

      login_data.each do |login, data|
        next if existing.include?(login.downcase)

        if OpenProject::Enterprise.user_limit_reached?
          Rails.logger.error("[LDAP departments] User '#{login}' could not be created as user limit exceeded.")
          break
        end

        try_to_create(data)
      end
    end

    def try_to_create(attrs)
      call = Users::CreateService.new(user: User.system).call(attrs)
      if call.success?
        Rails.logger.info("[LDAP departments] User '#{call.result.login}' created")
      else
        Rails.logger.error("[LDAP departments] User '#{call.result&.login}' could not be created: #{call.message}")
      end
    end
  end
end
