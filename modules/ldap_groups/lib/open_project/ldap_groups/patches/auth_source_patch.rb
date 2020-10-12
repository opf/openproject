module OpenProject::LdapGroups
  module Patches
    module AuthSourcePatch
      def self.included(base) # :nodoc:
        base.class_eval do
          has_many :ldap_groups_synchronized_groups,
                   class_name: '::LdapGroups::SynchronizedGroup',
                   dependent: :destroy
        end
      end
    end
  end
end
