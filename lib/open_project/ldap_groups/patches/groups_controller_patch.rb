module OpenProject::LdapGroups::Patches
  module GroupsControllerPatch

    ##
    # Adds a patch to restrict group membership changes
    # through the administration menu.
    def self.included(base)
      base.class_eval do
        include InstanceMethods

        alias_method_chain :remove_user, :ldap_groups
      end
    end

    module InstanceMethods

      ##
      # Removes a given user id with GroupsController.remove_user
      # IFF the user wasn't added by ldap.
      def remove_user_with_ldap_groups

        # Determine if association was made from ldap
        group_user = GroupUser.from_ldap.where(group_id: params[:id])
          .where(user_id: params[:user_id]).first

        if group_user
          @group = group_user.group
          flash[:error] = l(:membership_made_from_ldap, :username => group_user.user.login)
          respond_to do |format|
            format.html { redirect_to :controller => '/groups', :action => 'edit', :id => @group, :tab => 'users' }
            format.js { render :action => 'change_members' }
          end
        else
          remove_user_without_ldap_groups
        end

      end
    end

  end
end
