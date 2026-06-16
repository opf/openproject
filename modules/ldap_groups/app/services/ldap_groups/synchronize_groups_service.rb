# frozen_string_literal: true

module LdapGroups
  class SynchronizeGroupsService
    attr_reader :ldap, :synced_groups

    def initialize(ldap)
      @ldap = ldap

      # Get current synced groups in OP
      @synced_groups = ::LdapGroups::SynchronizedGroup.where(ldap_auth_source: ldap).includes(:filter)
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

      User.where("LOWER(login) IN (?)", entries.keys.map(&:downcase))
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
    # Get the current members from the ldap group.
    # Dispatches to forward or reverse lookup based on filter configuration.
    def get_members(ldap_con, group)
      if group.filter&.forward_member_lookup?
        Rails.logger.info { "[LDAP groups] Using forward lookup (#{group.filter.member_lookup_attribute}) for #{group.dn}" }
        get_members_forward(ldap_con, group)
      else
        Rails.logger.info { "[LDAP groups] Using reverse lookup (memberOf) for #{group.dn}" }
        get_members_reverse(ldap_con, group)
      end
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

    private

    ##
    # Reverse lookup (default): search users in the LDAP base with (memberOf=<group_dn>).
    # Requires the memberOf attribute to be present on user entries (AD, OpenLDAP with memberof overlay).
    def get_members_reverse(ldap_con, group)
      users = {}
      ldap_con.search(base: ldap.base_dn,
                      filter: memberof_filter(group),
                      attributes: ldap.search_attributes) do |entry|
        map_entry_to_users(entry, users)
      end
      users
    end

    ##
    # Forward lookup: read member DNs from the group entry itself, then resolve each DN.
    # Supports servers using groupOfUniqueNames (uniqueMember), groupOfNames (member), etc.
    def get_members_forward(ldap_con, group)
      member_attribute = group.filter.member_lookup_attribute
      member_dns = read_group_member_dns(ldap_con, group.dn, member_attribute)
      return {} if member_dns.empty?

      Rails.logger.info { "[LDAP groups] Forward lookup: #{member_dns.count} member DN(s) found on #{group.dn}" }
      users = resolve_member_dns(ldap_con, member_dns)
      Rails.logger.info { "[LDAP groups] Forward lookup complete for #{group.dn}: #{users.size} user(s) resolved" }
      users
    end

    def resolve_member_dns(ldap_con, member_dns)
      users = {}
      member_dns.each do |member_dn|
        Rails.logger.debug { "[LDAP groups] Resolving member DN: #{member_dn}" }
        resolved = false
        ldap_con.search(base: member_dn,
                        scope: Net::LDAP::SearchScope_BaseObject,
                        filter: Net::LDAP::Filter.present("objectClass"),
                        attributes: ldap.search_attributes) do |entry|
          resolved = true
          map_entry_to_users(entry, users)
        end
        unless resolved
          Rails.logger.warn do
            "[LDAP groups] Could not resolve member DN: #{member_dn}. " \
              "Entry not found or service account lacks read permission."
          end
        end
      end
      users
    end

    ##
    # Read the list of member DNs from a group entry using the configured attribute.
    def read_group_member_dns(ldap_con, group_dn, member_attribute)
      dns = []
      ldap_con.search(base: group_dn,
                      scope: Net::LDAP::SearchScope_BaseObject,
                      filter: Net::LDAP::Filter.present("objectClass"),
                      attributes: [member_attribute]) do |entry|
        # entry[attr] returns an array of all values for multi-valued attributes
        dns = Array(entry[member_attribute])
      end

      if dns.empty?
        Rails.logger.warn do
          "[LDAP groups] No entries returned for group DN: #{group_dn}. " \
            "The group entry may not exist or the service account may lack read permission."
        end
      end

      dns
    end

    def map_entry_to_users(entry, users)
      data = ldap.get_user_attributes_from_ldap_entry(entry)
      if data[:login].present?
        Rails.logger.debug { "[LDAP groups] Mapped #{entry.dn} -> login=#{data[:login]}" }
        users[data[:login]] = data.except(:dn)
      else
        log_missing_login(entry)
      end
    end

    def log_missing_login(entry)
      Rails.logger.warn do
        "[LDAP groups] Login attribute '#{ldap.attr_login}' not found or empty for #{entry.dn}. " \
          "Available attributes: #{entry.attribute_names.join(', ')}"
      end
    end

    ##
    # Build the memberOf filter for reverse lookup, combined with the auth source filter if set.
    def memberof_filter(group)
      filter = Net::LDAP::Filter.eq("memberOf", group.dn)

      if ldap.filter_string.present?
        filter = filter & ldap.parsed_filter_string
      end

      filter
    end
  end
end
