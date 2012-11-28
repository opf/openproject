require_dependency "project"
require_dependency "principal"

module GlobalRoles
  module PrincipalPatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable

        has_many :principal_roles, :dependent => :destroy
        has_many :global_roles, :through => :principal_roles, :source => :role
      end
    end
  end
end

Principal.send(:include, GlobalRoles::PrincipalPatch)
