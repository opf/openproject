# frozen_string_literal: true

module OpenProject::LdapGroups
  module Patches
    module LdapAuthSourcePatch
      def self.included(base) # :nodoc:
        base.class_eval do
          has_many :ldap_groups_synchronized_groups,
                   class_name: "::LdapGroups::SynchronizedGroup",
                   dependent: :destroy

          has_many :ldap_groups_synchronized_filters,
                   class_name: "::LdapGroups::SynchronizedFilter",
                   dependent: :destroy
        end
      end
    end
  end
end
