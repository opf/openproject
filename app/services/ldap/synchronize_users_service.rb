module Ldap
  class SynchronizeUsersService < BaseService
    attr_reader :logins

    def initialize(ldap, logins = nil)
      super(ldap)
      @logins = logins
    end

    private

    def perform
      ldap_con = new_ldap_connection

      applicable_users.find_each do |user|
        synchronize_user(user, ldap_con)
      rescue ::LdapAuthSource::Error => e
        Rails.logger.error { "Failed to synchronize user #{ldap.name} due to LDAP error: #{e.message}" }
        # Reset the LDAP connection
        ldap_con = new_ldap_connection
      rescue StandardError => e
        Rails.logger.error { "Failed to synchronize user #{ldap.name}: #{e.message}" }
      end
    end

    # Get the applicable users
    # as the service can be called with just a subset of users
    # from rake/external services.
    def applicable_users
      if logins.present?
        ldap.users.where("LOWER(login) in (?)", logins.map(&:downcase))
      else
        ldap.users
      end
    end
  end
end
