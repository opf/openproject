module Ldap
  class BaseService
    attr_reader :ldap

    def initialize(ldap)
      @ldap = ldap
    end

    def call
      User.system.run_given do
        OpenProject::Mutex.with_advisory_lock_transaction(ldap, self.class.name) do
          perform
        end
      end
    end

    def perform
      raise NotImplementedError
    end

    # rubocop:disable Metrics/AbcSize
    def synchronize_user(user, ldap_con)
      Rails.logger.debug { "[LDAP user sync] Synchronizing user #{user.login}." }

      update_attributes = user_attributes(user.login, ldap_con)
      if update_attributes.nil? && user.persisted?
        Rails.logger.info { "Could not find user #{user.login} in #{ldap.name}. Locking the user." }
        user.update_column(:status, Principal.statuses[:locked])
      end
      return unless update_attributes

      if user.new_record?
        try_to_create(update_attributes)
      else
        try_to_update(user, update_attributes)
      end
    end
    # rubocop:enable Metrics/AbcSize

    # Try to create the user from attributes
    def try_to_update(user, attrs)
      call = Users::UpdateService
        .new(model: user, user: User.system)
        .call(attrs)

      if call.success?
        # Ensure the user is activated
        call.result.update_column(:status, Principal.statuses[:active])
        Rails.logger.info { "[LDAP user sync] User '#{call.result.login}' updated." }
      else
        Rails.logger.error { "[LDAP user sync] User '#{user.login}' could not be updated: #{call.message}" }
      end
    end

    def try_to_create(attrs)
      call = Users::CreateService
        .new(user: User.system)
        .call(attrs)

      if call.success?
        Rails.logger.info { "[LDAP user sync] User '#{call.result.login}' created." }
      else
        Rails.logger.error { "[LDAP user sync] User '#{attrs[:login]}' could not be created: #{call.message}" }
      end
    end

    ##
    # Get the user attributes of a single matching LDAP entry.
    #
    # If the login matches multiple entries, return nil and issue a warning.
    # If the login does not match, returns nil
    def user_attributes(login, ldap_con)
      # Return the first matching user
      entries = find_entries_by(login: login, ldap_con: ldap_con)

      if entries.count == 0
        Rails.logger.info { "[LDAP user sync] Did not find LDAP entry for #{login}" }
        return
      end

      if entries.count > 1
        Rails.logger.warn { "[LDAP user sync] Found multiple entries for #{login}: #{entries.map(&:dn)}. Skipping" }
        return
      end

      entries.first
    end

    def find_entries_by(login:, ldap_con: new_ldap_connection)
      ldap_con
        .search(
          base: ldap.base_dn,
          filter: ldap.login_filter(login),
          attributes: ldap.search_attributes(true)
        )
        .map { |entry| ldap.get_user_attributes_from_ldap_entry(entry).except(:dn) }
    end

    def new_ldap_connection
      ldap.instance_eval { initialize_ldap_con(account, account_password) }
    end
  end
end
