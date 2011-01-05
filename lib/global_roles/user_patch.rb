require_dependency "project"
require_dependency "user"

module GlobalRoles
  module UserPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        alias_method_chain :allowed_to?, :principal_roles
      end
    end

    module InstanceMethods
      def allowed_to_with_principal_roles?(action, project, options={})
        allowing_role_or_bool = allowed_to_without_principal_roles?(action, project, options)

        if options[:global] && !allowing_role_or_bool
          allowing_role_or_bool = allowed_to_by_principal_roles?(action)
        end

        allowing_role_or_bool
      end

      private

      def allowed_to_by_principal_roles?(action)
        allowing_roles = allowing_principal_roles(action)
        allowing_roles.size > 0 ? allowing_roles[0].role : false
      end

      def allowing_principal_roles(action)
        principal_roles.find_all{ |pr| pr.role.allowed_to?(action) }
      end
    end
  end
end

User.send(:include, GlobalRoles::UserPatch)
