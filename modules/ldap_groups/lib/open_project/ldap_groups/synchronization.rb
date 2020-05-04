module OpenProject::LdapGroups
  class Synchronization
    attr_reader :ldap, :synced_groups

    def initialize(ldap)
      @ldap = ldap

      # Get current synced groups in OP
      @synced_groups = ::LdapGroups::SynchronizedGroup.where(auth_source: ldap)

      synchronize!
    rescue StandardError => e
      error = "[LDAP groups] Failed to perform LDAP group synchronization: #{e.class}: #{e.message}"
      Rails.logger.error(error)
    end

    def synchronize!
      ldap_con = ldap.instance_eval { initialize_ldap_con(account, account_password) }

      ::LdapGroups::Membership.transaction do
        @synced_groups.find_each do |group|
          user_data = get_members(ldap_con, group)

          # Create users that are not existing
          users = map_to_users(user_data)

          update_memberships!(group, users)
        end
      end
    end

    ##
    # Map LDAP entries to user accounts, creating them if necessary
    def map_to_users(entries)
      create_missing!(entries) if ldap.onthefly_register?

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

      # memberOf filter to identifiy member entries of the group
      memberof_filter = Net::LDAP::Filter.eq('memberOf', group.dn)

      users = {}
      ldap_con.search(base: base_dn,
                      filter: ldap.default_filter & memberof_filter,
                      attributes: ldap.search_attributes) do |entry|
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

      # Bulk insert the memberships
      memberships = new_member_ids.map do |user_id|
        {
          group_id: sync.id,
          user_id: user_id
        }
      end
      ::LdapGroups::Membership.insert_all memberships
      sync.group.add_members! new_member_ids
    end

    ##
    # Remove a set of memberships
    def remove_memberships!(memberships, sync)
      if memberships.empty?
        Rails.logger.info "[LDAP groups] No users to remove for #{sync.dn}"
        return
      end

      Rails.logger.info "[LDAP groups] Removing users #{memberships.pluck(:user_id)} from #{sync.dn}"
      sync.remove_members!(memberships)
      memberships.delete_all
    end
  end
end
