require_dependency "users_controller"

module GlobalRoles
  module UsersControllerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        alias_method_chain :edit, :global_roles
      end
    end

    module InstanceMethods
      def edit_with_global_roles
        edit_without_global_roles
        @global_roles = GlobalRole.all
      end
    end
  end
end

UsersController.send(:include, GlobalRoles::UsersControllerPatch)
