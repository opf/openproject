module OpenProject::LdapGroups::Patches
  module GroupUserPatch

    ##
    # Adds a patch to add a scope identifying
    # memberships set from ldap.
    def self.included(base)
      base.class_eval do
        scope :from_ldap, -> { where from_ldap: true }
      end
    end

  end
end
