module Ldap
  class ImportUsersFromFilterService < BaseService
    attr_reader :filter

    def initialize(ldap, filter)
      super(ldap)
      @filter = filter
    end

    def perform
      get_entries_from_filter do |entry|
        attributes = ldap.get_user_attributes_from_ldap_entry(entry)
        next if User.by_login(attributes[:login]).exists?

        try_to_create attributes.except(:dn)
      end
    end

    def get_entries_from_filter(&)
      ldap_con = new_ldap_connection

      ldap_con.search(
        base: ldap.base_dn,
        filter: filter & ldap.default_filter,
        attributes: ldap.search_attributes,
        &
      )
    end
  end
end
