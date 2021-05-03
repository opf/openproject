module LdapGroups
  class SynchronizationService
    def self.synchronize!
      new.call
    end

    def call
      LdapAuthSource.find_each do |ldap|
        Rails.logger.info { "[LDAP groups] Retrieving groups from filters for ldap auth source #{ldap.name}" }
        LdapGroups::SynchronizedFilter
          .where(auth_source_id: ldap.id)
          .find_each do |filter|

          LdapGroups::SynchronizeFilterService
            .new(filter)
            .call
        end

        Rails.logger.info { "[LDAP groups] Start group synchronization for ldap auth source #{ldap.name}" }
        LdapGroups::SynchronizeGroupsService.new(ldap).call
      end
    rescue StandardError => e
      msg = "[LDAP groups] Failed to run LDAP group synchronization. #{e.class.name}: #{e.message}"
      Rails.logger.error msg
    end
  end
end
