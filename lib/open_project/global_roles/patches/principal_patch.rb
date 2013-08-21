module OpenProject::GlobalRoles::Patches
  module PrincipalPatch
    def self.included(base)
      base.class_eval do

        has_many :principal_roles, :dependent => :destroy
        has_many :global_roles, :through => :principal_roles, :source => :role
      end
    end
  end
end

Principal.send(:include, OpenProject::GlobalRoles::Patches::PrincipalPatch)
