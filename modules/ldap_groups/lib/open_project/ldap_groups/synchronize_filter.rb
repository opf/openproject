module OpenProject::LdapGroups
  class SynchronizeFilter
    attr_reader :filter, :raise_errors

    def initialize(filter, raise_errors: false)
      @filter = filter
      @raise_errors = raise_errors
      synchronize!
    end

    private

    ##
    # Perform the synchronization for the given filter
    def synchronize!
      # Replace the filter groups, this will remove any groups
      # no longer found in ldap
      filter.groups.replace upstream_groups
    rescue StandardError => e
      error = "[LDAP groups] Failed to extract LDAP groups from filter #{filter.name}: #{e.class}: #{e.message}"
      Rails.logger.error(error)
      raise(e) if raise_errors
    end

    ##
    # Get the current members from the ldap group
    def upstream_groups
      groups = []

      each_group do |dn, name|
        entry = LdapGroups::SynchronizedGroup.find_or_initialize_by(dn: dn)
        # Always set the filter and auth source, in case multiple filters match the same group
        # they are simply being re-assigned to the latest one
        entry.filter_id = filter.id
        entry.auth_source_id = filter.auth_source_id

        # Create an OpenProject group
        unless entry.group_id
          entry.group = Group.find_or_initialize_by(groupname: name)
        end

        groups << entry
      end

      groups
    end

    ##
    # Find groups by the filter string
    # and yield them one by one
    def each_group
      ldap = filter.auth_source
      base_dn = ldap.base_dn
      group_name = filter.group_name_attribute

      ldap.with_connection do |ldap_con|
        ldap_con
          .search(
            base: base_dn,
            filter: filter.parsed_filter_string,
            attributes: ['dn', group_name]
          ).each do |entry|

          yield entry.dn, LdapAuthSource.get_attr(entry, group_name)
        end
      end
    end
  end
end
