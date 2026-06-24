# frozen_string_literal: true

module OpenProject::LdapDepartments
  module Patches
    module LdapAuthSourcePatch
      def self.included(base) # :nodoc:
        base.class_eval do
          has_many :ldap_departments_synchronized_trees,
                   class_name: "::LdapDepartments::SynchronizedTree",
                   dependent: :destroy

          has_many :ldap_departments_synchronized_departments,
                   class_name: "::LdapDepartments::SynchronizedDepartment",
                   dependent: :destroy
        end
      end
    end
  end
end
