module LdapGroups
  class SynchronizeGroupsService
    attr_reader :ldap, :synced_groups

    def initialize(ldap)
      @ldap = ldap

      # Get current synced groups in OP
      @synced_groups = ::LdapGroups::SynchronizedGroup.where(ldap_auth_source: ldap)
    end

    def call
      synchronize!
      ServiceResult.success
    rescue StandardError => e
      error = "[LDAP groups] Failed to perform LDAP group synchronization: #{e.class}: #{e.message}"
      Rails.logger.error(error)
      ServiceResult.failure(message: error)
    end

    def synchronize!
      ldap_con = ldap.instance_eval { initialize_ldap_con(account, account_password) }

      @synced_groups.find_each do |sync_group|
        OpenProject::Mutex.with_advisory_lock_transaction(sync_group) do
          synchronize_members(sync_group, ldap_con)
        end
      end
    end

    def synchronize_members(sync_group, ldap_con)
      user_data = get_members(ldap_con, sync_group)

      # Create users that are not existing
      users = map_to_users(sync_group, user_data)

      update_memberships!(sync_group, users)
    rescue StandardError => e
      Rails.logger.error "[LDAP groups] Failed to synchronize group: #{sync_group.dn}: #{e.class} #{e.message}"
      raise e
    end

    ##
    # Map LDAP entries to user accounts, creating them if necessary
    def map_to_users(sync_group, entries)
      create_missing!(entries) if sync_group.sync_users

      User.where('LOWER(login) IN (?)', entries.keys.map(&:downcase))
    end

    ##
    # Create missing users from ldap data
    def create_missing!(entries)
      existing = User.where(login: entries.keys).pluck(:login, :id).to_h

      entries.each do |login, data|
        next if existing[login]

        if OpenProject::Enterprise.user_limit_reached?
          Rails.logger.error("[LDAP groups] User '#{login}' could not be created as user limit exceeded.")
          break
        end

        try_to_create(data)
      end
    end

    # Try to create the user from attributes
    def try_to_create(attrs)
      call = Users::CreateService
        .new(user: User.system)
        .call(attrs)

      if call.success?
        Rails.logger.info("[LDAP groups] User '#{call.result.login}' created")
      else
        Rails.logger.error("[LDAP groups] User '#{call.result&.login}' could not be created: #{call.message}")
      end
    end

    ##
    # Apply memberships from the ldap group and remove outdated
    def update_memberships!(sync, users)
      # Remove group users no longer in ids
      no_longer_present = ::LdapGroups::Membership.where(group_id: sync.id).where.not(user_id: users.select(:id))
      remove_memberships!(no_longer_present, sync)

      # Add all current users from LDAP as members
      add_memberships!(users, sync)

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
      search_attributes = ldap.search_attributes
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
    def add_memberships!(ldap_member_ids, sync)
      if ldap_member_ids.empty?
        Rails.logger.info "[LDAP groups] No new users to add for #{sync.dn}"
        return
      end

      Rails.logger.info { "[LDAP groups] Making #{ldap_member_ids.count} members of #{sync.dn}" }

      sync.add_members! ldap_member_ids
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

      user_ids = memberships.pluck(:user_id)

      Rails.logger.info "[LDAP groups] Removing users #{user_ids.inspect} from #{sync.dn}"

      sync.remove_members! user_ids
    end
  end
end
