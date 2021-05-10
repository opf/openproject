module LdapGroups
  class SynchronizeGroupsService
    attr_reader :ldap, :synced_groups

    def initialize(ldap)
      @ldap = ldap

      # Get current synced groups in OP
      @synced_groups = ::LdapGroups::SynchronizedGroup.where(auth_source: ldap)
    end

    def call
      count = synchronize!
      ServiceResult.new(result: count, success: true)
    rescue StandardError => e
      error = "[LDAP groups] Failed to perform LDAP group synchronization: #{e.class}: #{e.message}"
      Rails.logger.error(error)
      ServiceResult.new(message: error, success: false)
    end

    def synchronize!
      ldap_con = ldap.instance_eval { initialize_ldap_con(account, account_password) }
      count = 0

      ::LdapGroups::Membership.transaction do
        @synced_groups.find_each do |sync_group|
          user_data = get_members(ldap_con, sync_group)

          # Create users that are not existing
          users = map_to_users(sync_group, user_data)

          update_memberships!(sync_group, users)

          count += users.count
        end
      end

      count
    end

    ##
    # Map LDAP entries to user accounts, creating them if necessary
    def map_to_users(sync_group, entries)
      create_missing!(entries) if sync_group.sync_users

      User.where(login: entries.keys)
    end

    ##
    # Create missing users from ldap data
    def create_missing!(entries)
      existing = User.where(login: entries.keys).pluck(:login, :id).to_h

      entries.each do |login, data|
        next if existing[login]

        User.try_to_create(data)
      end
    end

    ##
    # Apply memberships from the ldap group and remove outdated
    def update_memberships!(sync, users)
      # Get the user ids of the current members in ldap
      ldap_member_ids = users.pluck(:id)
      set_by_us = ::LdapGroups::Membership.where(group_id: sync.id, user_id: ldap_member_ids).pluck(:user_id)

      # Remove group users no longer in ids
      no_longer_present = ::LdapGroups::Membership.where(group_id: sync.id).where.not(user_id: ldap_member_ids)
      remove_memberships!(no_longer_present, sync)

      # Add new memberships
      group_members = sync.group.users.pluck(:id)
      new_member_ids = ldap_member_ids - set_by_us - group_members
      add_memberships!(new_member_ids, sync)

      # Reset the counters after manually inserting items
      LdapGroups::SynchronizedGroup.reset_counters(sync.id, :users, touch: true)
    end

    ##
    # Get the current members from the ldap group
    def get_members(ldap_con, group)
      # Get user login attribute and base dn which are private
      base_dn = ldap.base_dn

      users = {}
      # Override the default search attributes from the ldap
      # if we have sync_users enabled, to also get user attributes
      search_attributes = ldap.search_attributes(group.sync_users)
      ldap_con.search(base: base_dn,
                      filter: memberof_filter(group),
                      attributes: search_attributes) do |entry|
        data = ldap.get_user_attributes_from_ldap_entry(entry)
        users[data[:login]] = data.except(:dn)
      end

      users
    end

    ##
    # Add new users to the synced group
    def add_memberships!(new_member_ids, sync)
      if new_member_ids.empty?
        Rails.logger.info "[LDAP groups] No new users to add for #{sync.dn}"
        return
      end

      Rails.logger.info { "[LDAP groups] Adding #{new_member_ids.length} users to #{sync.dn}" }

      sync.add_members! new_member_ids
    end

    ##
    # Get the memberof filter to use for querying members
    def memberof_filter(group)
      # memberOf filter to identify member entries of the group
      filter = Net::LDAP::Filter.eq('memberOf', group.dn)

      # Add the LDAP auth source own filter if present
      if ldap.filter_string.present?
        filter = filter & ldap.parsed_filter_string
      end

      filter
    end

    ##
    # Remove a set of memberships
    def remove_memberships!(memberships, sync)
      if memberships.empty?
        Rails.logger.info "[LDAP groups] No users to remove for #{sync.dn}"
        return
      end

      Rails.logger.info "[LDAP groups] Removing users #{memberships.pluck(:user_id)} from #{sync.dn}"

      sync.remove_members! memberships.pluck(:user_id)
    end
  end
end
