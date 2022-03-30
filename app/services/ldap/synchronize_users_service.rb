module Ldap
  class SynchronizeUsersService
    attr_reader :ldap, :logins

    def initialize(ldap, logins = nil)
      @ldap = ldap
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

    def new_ldap_connection
      ldap.instance_eval { initialize_ldap_con(account, account_password) }
    end

    def synchronize_user(user, ldap_con)
      Rails.logger.debug { "Synchronizing user #{user.login}." }

      update_attributes = user_attributes(user.login, ldap_con)
      if update_attributes
        try_to_update(user, update_attributes)
      else
        Rails.logger.info { "Could not find user #{user.login} in #{ldap.name}. Locking the user." }
        user.update_column(:status, Principal.statuses[:locked])
      end
    end

    # Try to create the user from attributes
    # rubocop:disable Metrics/AbcSize
    def try_to_update(user, attrs)
      call = Users::UpdateService
        .new(model: user, user: User.system)
        .call(attrs.merge)

      if call.success?
        # Ensure the user is activated
        call.result.update_column(:status, Principal.statuses[:active])
        Rails.logger.info { "[LDAP user sync] User '#{call.result.login}' updated" }
      else
        Rails.logger.error { "[LDAP user sync] User '#{user.login}' could not be updated: #{call.message}" }
      end
    end
    # rubocop:enable Metrics/AbcSize

    def user_attributes(login, ldap_con)
      # Get user login attribute and base dn which are private
      base_dn = ldap.base_dn

      search_attributes = ldap.search_attributes(true)
      login_filter = Net::LDAP::Filter.eq(ldap.attr_login, login)
      ldap_con.search(base: base_dn,
                      filter: ldap.default_filter & login_filter,
                      attributes: search_attributes) do |entry|
        data = ldap.get_user_attributes_from_ldap_entry(entry)
        return data.except(:dn)
      end

      nil
    end
  end
end
