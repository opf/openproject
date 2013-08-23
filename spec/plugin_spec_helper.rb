#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2010-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module GlobalRoles
    module PluginSpecHelper
      def mobile_tan_plugin_loaded?
        plugin_loaded?("openproject_mobile_otp_authentication")
      end

      def privacy_plugin_loaded?
        plugin_loaded?("openproject_dtag_privacy")
      end

      def costs_plugin_loaded?
        plugin_loaded?("openproject_costs")
      end

      def plugin_loaded?(name)
        Redmine::Plugin.all.detect {|x| x.id == name.to_sym}.present?
      end

      def mocks_for_member_roles
        @role = mock_model Role
        Role.stub!(:new).and_return(@role)

        mock_permissions_on @role

        mock_role_find

        @non_mem = mock_model Role
        @non_mem.stub!(:permissions).and_return(@non_mem_perm)
        Role.stub!(:non_member).and_return(@non_mem)
        @non_mem_perm = [:nm_perm1, :nm_perm2]
      end

      def mocks_for_global_roles
        @role = mock_model GlobalRole
        GlobalRole.stub!(:new).and_return(@role)
        mock_permissions_on @role
      end

      def mock_permissions_on role
        permissions = [:perm1, :perm2, :perm3]
        role.stub!(:setable_permissions).and_return(permissions)
        role.stub!(:permissions).and_return(permissions << :perm4)
      end

      def mock_role_find
        mock_member_role_find
        mock_global_role_find
      end

      def mock_member_role_find
        @role1 = mock_model Role
        @role2 = mock_model Role
        @global_role1 = mock_model GlobalRole
        @global_role2 = mock_model GlobalRole
        @roles = [@role1, @global_role2, @role2, @global_role1]
        Role.stub!(:find).and_return(@roles)
        Role.stub!(:all).and_return(@roles)
        Role.stub!(:order).and_return(@roles)
        @roles.stub!(:page).and_return(@roles)
        @roles.stub!(:per_page).and_return(@roles)
      end

      def mock_global_role_find
        @global_role1 = mock_model GlobalRole
        @global_role2 = mock_model GlobalRole
        @global_roles = [@global_role1, @global_role2]
        GlobalRole.stub!(:find).and_return(@global_roles)
        GlobalRole.stub!(:all).and_return(@global_roles)
      end

      def mocks_for_creating role_class
        role = mock_model role_class
        role_class.stub!(:new).and_return role
        mock_permissions_on role
        role
      end

      def disable_flash_sweep
       @controller.instance_eval{flash.stub!(:sweep)}
      end

      def disable_log_requesting_user
        @controller.stub!(:log_requesting_user)
      end

      def response_should_render method, *params
        unless @page
          @page ||= mock("page")
          controller.should_receive(:render).with(:update).and_yield(@page)
          #fix for implicit render without parameters being called in test
          controller.should_receive(:render).with
        end

        @page.should_receive(method).with(*params)
      end

      def mock_permissions_for_setable_permissions
        @public_perm = mock_permissions(true, false)
        @perm1 = mock_permissions(false, false)
        @perm2 = mock_permissions(false, false)
        @global_perm = mock_permissions(false, true)

        @perms = [@public_perm, @perm1, @global_perm, @perm2]
        Redmine::AccessControl.stub!(:permissions).and_return(@perms)
        Redmine::AccessControl.stub!(:public_permissions).and_return([@public_perm])
        Redmine::AccessControl.stub!(:global_permissions).and_return([@global_perm])
      end

      def mock_permissions(is_public, is_global)
        permission = Object.new
        permission.stub!(:public?).and_return(is_public)
        permission.stub!(:global?).and_return(is_global)
        permission
      end

      def create_non_member_role
        create_builtin_role 'No member', Role::BUILTIN_NON_MEMBER
      end

      def create_anonymous_role
        create_builtin_role "Anonymous", Role::BUILTIN_ANONYMOUS
      end

      def create_builtin_role(name, const)
        Role.create(:name => name, :position => 0) do |role|
          role.builtin = const
        end
      end

      def stash_access_control_permissions
        @stashed_permissions = Redmine::AccessControl.permissions.dup
        Redmine::AccessControl.permissions.clear
      end

      def restore_access_control_permissions
        Redmine::AccessControl.instance_variable_set(:@permissions, @stashed_permissions)
      end
    end
  end
end
