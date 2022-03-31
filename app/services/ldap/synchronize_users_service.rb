module Ldap
  class SynchronizeUsersService < BaseService
    attr_reader :logins

    def initialize(ldap, logins = nil)
      super(ldap)
      @logins = logins
    end

    def call
      Rails.logger.debug { "Start LDAP user synchronization for #{ldap.name}." }
      User.system.run_given do
        OpenProject::Mutex.with_advisory_lock_transaction(ldap, 'synchronize_users') do
          synchronize!
        end
      end
    end

    private

    def synchronize!
      ldap_con = new_ldap_connection

      applicable_users.find_each do |user|
        synchronize_user(user, ldap_con)
      rescue ::AuthSource::Error => e
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
