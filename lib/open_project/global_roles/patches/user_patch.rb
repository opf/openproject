module OpenProject::GlobalRoles::Patches
  module UserPatch
    def self.included(base)
      base.class_eval do

        has_many :principal_roles, :dependent => :destroy, :foreign_key => 'principal_id'
        has_many :global_roles, :through => :principal_roles, :source => :role
      end
    end
  end
end

User.send(:include, OpenProject::GlobalRoles::Patches::UserPatch)
