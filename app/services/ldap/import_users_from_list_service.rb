module Ldap
  class ImportUsersFromListService < BaseService
    attr_reader :logins

    def initialize(ldap, logins)
      super(ldap)
      @logins = logins
    end

    def perform
      new_users = logins - existing_users

      Rails.logger.debug { "Importing LDAP user import for #{ldap.name} for #{new_users.count} new users." }
      import! new_users
    end

    def import!(new_users)
      ldap_con = new_ldap_connection

      new_users.each do |login|
        synchronize_user(User.new(login:), ldap_con)
      rescue ::LdapAuthSource::Error => e
        Rails.logger.error { "Failed to synchronize user #{ldap.name} due to LDAP error: #{e.message}" }
        # Reset the LDAP connection
        ldap_con = new_ldap_connection
      rescue StandardError => e
        Rails.logger.error { "Failed to synchronize user #{ldap.name}: #{e.message}" }
      end
    end

    def existing_users
      User.where("LOWER(login) in (?)", logins.map(&:downcase)).pluck(:login)
    end
  end
end
