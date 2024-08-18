module LdapGroups
  class SynchronizeFilterService
    attr_reader :filter

    def initialize(filter)
      @filter = filter
    end

    def call
      count = synchronize!
      ServiceResult.success(result: count)
    rescue StandardError => e
      error = "[LDAP groups] Failed to extract LDAP groups from filter #{filter.name}: #{e.class}: #{e.message}"
      Rails.logger.error(error)
      ServiceResult.failure(message: error)
    end

    ##
    # Perform the synchronization for the given filter
    def synchronize!
      # Replace the filter groups, this will remove any groups
      # no longer found in ldap
      groups = upstream_groups
      filter.groups.replace groups

      groups.count
    end

    private

    ##
    # Get the current members from the ldap group
    def upstream_groups
      groups = []

      each_group do |dn, name|
        sync = create_or_update_sync_group(dn)
        create_or_update_group(sync, name)

        groups << sync
      end

      groups
    end

    ##
    # Find groups by the filter string
    # and yield them one by one
    def each_group
      ldap = filter.ldap_auth_source
      ldap.with_connection do |ldap_con|
        search(filter, ldap_con) do |entry|
          yield entry.dn, LdapAuthSource.get_attr(entry, filter.group_name_attribute)
        end
      end
    end

    ##
    # Perform the LDAP search for the groups
    def search(filter, ldap_con, &)
      ldap_con.search(
        base: filter.used_base_dn,
        filter: filter.parsed_filter_string,
        attributes: ["dn", filter.group_name_attribute],
        &
      )
    end

    ##
    # Create or update the synchronized group item
    def create_or_update_sync_group(dn)
      group = LdapGroups::SynchronizedGroup
        .find_or_initialize_by(dn:).tap do |sync|
        # Always set the filter and auth source, in case multiple filters match the same group
        # they are simply being re-assigned to the latest one
        sync.filter_id = filter.id
        sync.ldap_auth_source_id = filter.ldap_auth_source_id

        # Tell the group to synchronize users if the filter has requested it to
        sync.sync_users = filter.sync_users
      end

      group.tap { group.save! if group.persisted? }
    end

    ##
    # Create or update the group
    def create_or_update_group(sync, name)
      if sync.group_id
        # Update the group name
        Group.where(id: sync.group_id).update_all(lastname: name)
      else
        # Create an OpenProject group
        sync.group = Group.find_or_create_by!(name:)
      end
    end
  end
end
