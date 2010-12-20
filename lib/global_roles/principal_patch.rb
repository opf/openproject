require_dependency "principal"

module GlobalRoles
  module PrincipalPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        has_many :principal_roles
        has_many :global_roles, :through => :principal_roles, :source => :role
      end
    end

    module InstanceMethods

    end
  end
end

Principal.send(:include, GlobalRoles::PrincipalPatch)
