module GlobalRoles
  module RolePatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :setable_permissions, :no_global_roles
      end
    end

    module InstanceMethods
      def setable_permissions_with_no_global_roles
        setable_permissions = setable_permissions_without_no_global_roles
        setable_permissions -= Redmine::AccessControl.global_permissions
        setable_permissions
      end
    end
  end
end

Role.send(:include, GlobalRoles::RolePatch)