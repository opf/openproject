module OpenProject::LdapGroups
  module Patches
    module UserPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          has_many :ldap_groups_memberships,
                   class_name: "::LdapGroups::Membership",
                   dependent: :destroy
        end
      end
    end
  end
end
