module GlobalRoles
  module RolesControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :new, :global_roles
        alias_method_chain :index, :global_roles
        alias_method_chain :list, :global_roles if Redmine::VERSION::MAJOR < 1
      end
    end

    module InstanceMethods
      def create
        if params['global_role']
          create_global_role
        else
          new

          render :template => 'roles/new' if @role.errors.size > 0
        end
      end

      def new_with_global_roles
        new_without_global_roles

        @member_permissions = (@role.setable_permissions || @permissions)
        @global_permissions = GlobalRole.setable_permissions
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

      def update
        edit

        render :template => 'roles/edit' if @role.errors.size > 0
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

      def standard_member_and_global_assigns
        @member_permissions = (@member_role.setable_permissions || @permissions)
        @global_permissions = GlobalRole.setable_permissions
        @global_roles = GlobalRole.all
        @member_roles = (Role.all || @roles)
      end
    end
  end
end

RolesController.send(:include, GlobalRoles::RolesControllerPatch)