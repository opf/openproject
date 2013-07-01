module OpenProject::GlobalRoles::Patches
  module RolesControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :create, :global_roles
        alias_method_chain :new, :global_roles
      end
    end

    module InstanceMethods

      def new_with_global_roles
        new_without_global_roles

        @member_permissions = (@role.setable_permissions || @permissions)
        @global_permissions = GlobalRole.setable_permissions
      end

       def create_with_global_roles
        if params['global_role']
          create_global_role
        else
          create_without_global_roles

          @member_permissions = (@role.setable_permissions || @permissions)
          @global_permissions = GlobalRole.setable_permissions
        end
      end

      private

      def create_global_role
        @role = GlobalRole.new params[:role]
        if @role.save
          flash[:notice] = l(:notice_successful_create)
          redirect_to :action => 'index'
        else
          @roles = Role.all :order => 'builtin, position'
          @member_permissions = Role.new.setable_permissions
          @global_permissions = GlobalRole.setable_permissions
          render :template => 'roles/new'
        end
      end
    end
  end
end

RolesController.send(:include, OpenProject::GlobalRoles::Patches::RolesControllerPatch)
