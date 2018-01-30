module OpenProject::LdapGroups
  class Synchronization
    attr_reader :ldap, :synced_groups

    def initialize(ldap)
      @ldap = ldap

      # Get current synced groups in OP
      @synced_groups = ::LdapGroups::SynchronizedGroup.where(auth_source: ldap)

      begin
        synchronize!
      rescue => e
        error = "Failed to perform LDAP group synchronization: #{e.class}: #{e.message}"
        Rails.logger.error(error)
        warn error
      end
    end

    def synchronize!
      ldap_con = ldap.instance_eval { initialize_ldap_con(account, account_password) }

      ::LdapGroups::Membership.transaction do
        @synced_groups.find_each do |group|
          members = get_members(ldap_con, group)
          users = User.where(login: members)
          update_memberships!(group, users)
        end
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
      new_members = ldap_member_ids - set_by_us
      new_users = User.where(id: new_members)
      add_memberships!(new_users, sync)
    end

    ##
    # Get the current members from the ldap group
    def get_members(ldap_con, group)
      group_filter = Net::LDAP::Filter.eq(::OpenProject::LdapGroups.group_key, group.escaped_entry)
      object_filter = Net::LDAP::Filter.eq('objectClass', '*')

      logins = []
      ldap_con.search(base: ::OpenProject::LdapGroups.group_base,
                      filter: object_filter & group_filter,
                      attributes: [:member]) do |entry|
        logins = entry[:member].map { |dn| dn.match(/\A\w+\=([^,]+)/)[1] }
      end

      logins
    end

    ##
    # Add new users to the synced group
    def add_memberships!(new_users, sync)
      if new_users.empty?
        puts "No new users to add for #{sync.entry}"
        return
      end

      puts "Adding users #{new_users.pluck(:login)} to #{sync.entry}"
      sync.users << new_users.map {|user| ::LdapGroups::Membership.new(group: sync, user: user)}
      sync.group.users << new_users
    end

    ##
    # Remove a set of memberships
    def remove_memberships!(memberships, sync)
      if memberships.empty?
        puts "No users to remove for #{sync.entry}"
        return
      end

      user_ids = memberships.pluck(:user_id)
      puts "Removing users #{user_ids} from #{sync.entry}"
      sync.group.users.delete(*user_ids)
      memberships.delete_all
    end
  end
end
