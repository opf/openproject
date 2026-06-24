# frozen_string_literal: true

module OpenProject::LdapDepartments
  module Patches
    module UserPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          has_many :ldap_departments_memberships,
                   class_name: "::LdapDepartments::Membership",
                   dependent: :destroy
        end
      end
    end
  end
end
