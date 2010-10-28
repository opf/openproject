module GlobalRoles
  module RolesControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :new, :global_roles
        alias_method_chain :index, :global_roles
        alias_method_chain :destroy, :global_roles
        alias_method_chain :list, :global_roles
      end
    end

    module InstanceMethods
      def create
        if params['global_role']
          create_global_role
        else
          new
          @global_role = GlobalRole.new
          standard_member_and_global_assigns
        end
      end

      def new_with_global_roles
        new_without_global_roles

        @member_role = @role
        @global_role = GlobalRole.new
        standard_member_and_global_assigns
      end

      def index_with_global_roles
        @role_pages, @roles = paginate :roles, :per_page => 25, :order => 'builtin, position'
        respond_to do |format|
          format.html {render :action => 'index'}
          format.js {render :action => 'index', :layout => false}
        end
      end

      def list_with_global_roles
        index_with_global_roles
      end

      def destroy_with_global_roles
        if params[:class] == GlobalRole.to_s
          destroy_global_role
        else
          destroy_without_global_roles
        end
      end

      private

      def create_global_role
        @global_role = GlobalRole.new params[:role]
        if @global_role.save
          flash[:notice] = l(:notice_successful_create)
          redirect_to :action => 'index'
        else
          @member_role = Role.new
          standard_member_and_global_assigns
        end
      end

      def destroy_global_role
        role = GlobalRole.find params[:id]
        role.destroy
        redirect_to :action => 'index'
      end

      def standard_member_and_global_assigns
        @member_permissions = (@member_role.setable_permissions || @permissions)
        @global_permissions = @global_role.setable_permissions
        @global_roles = GlobalRole.all
        @member_roles = (Role.all || @roles)
      end
    end
  end
end

RolesController.send(:include, GlobalRoles::RolesControllerPatch)