# frozen_string_literal: true

module OpenProject::LdapDepartments
  module Patches
    module GroupPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          has_many :ldap_departments_synchronized_departments,
                   class_name: "::LdapDepartments::SynchronizedDepartment",
                   foreign_key: :group_id,
                   dependent: :destroy

          # A department is managed when an LDAP organizational unit is mapped onto it. Only
          # organizational units can ever be managed, so skip the lookup for regular groups.
          register_ldap_managed_check do |group|
            next false if group.new_record?
            next false unless group.organizational_unit?

            group.ldap_departments_synchronized_departments.exists?
          end
        end
      end
    end
  end
end
