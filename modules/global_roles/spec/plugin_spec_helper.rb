#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module OpenProject
  module GlobalRoles
    module PluginSpecHelper
      def mobile_tan_plugin_loaded?
        plugin_loaded?('openproject_mobile_otp')
      end

      def privacy_plugin_loaded?
        plugin_loaded?('openproject_dtag_customizing')
      end

      def costs_plugin_loaded?
        plugin_loaded?('openproject_costs')
      end

      def plugin_loaded?(name)
        Redmine::Plugin.all.detect { |x| x.id == name.to_sym }.present?
      end

      def mocks_for_member_roles
        @role = mock_model Role
        allow(Role).to receive(:new).and_return(@role)

        mock_permissions_on @role

        mock_role_find

        @non_mem = mock_model Role
        allow(@non_mem).to receive(:permissions).and_return(@non_mem_perm)
        allow(Role).to receive(:non_member).and_return(@non_mem)
        @non_mem_perm = [:nm_perm1, :nm_perm2]
      end

      def mocks_for_global_roles
        @role = mock_model GlobalRole
        allow(GlobalRole).to receive(:new).and_return(@role)
        mock_permissions_on @role
      end

      def mock_permissions_on(role)
        permissions = [:perm1, :perm2, :perm3]
        allow(role).to receive(:setable_permissions).and_return(permissions)
        allow(role).to receive(:permissions).and_return(permissions << :perm4)
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
        allow(Role).to receive(:find).and_return(@roles)
        allow(Role).to receive(:all).and_return(@roles)
        allow(Role).to receive(:order).and_return(@roles)
        allow(@roles).to receive(:page).and_return(@roles)
        allow(@roles).to receive(:per_page).and_return(@roles)
      end

      def mock_global_role_find
        @global_role1 = mock_model GlobalRole
        @global_role2 = mock_model GlobalRole
        @global_roles = [@global_role1, @global_role2]
        allow(GlobalRole).to receive(:find).and_return(@global_roles)
        allow(GlobalRole).to receive(:all).and_return(@global_roles)
      end

      def mocks_for_creating(role_class)
        role = mock_model role_class
        allow(role_class).to receive(:new).and_return role
        mock_permissions_on role
        role
      end

      def disable_flash_sweep
        @controller.instance_eval { allow(flash).to receive(:sweep) }
      end

      def disable_log_requesting_user
        allow(@controller).to receive(:log_requesting_user)
      end

      def response_should_render(method, *params)
        unless @page
          @page ||= double('page')
          expect(controller).to receive(:render).with(:update).and_yield(@page)
          expect(controller).to receive(:render).with(no_args)
        end

        expect(@page).to receive(method).with(*params)
      end

      def mock_permissions_for_setable_permissions
        @public_perm = mock_permissions(true, false)
        @perm1 = mock_permissions(false, false)
        @perm2 = mock_permissions(false, false)
        @global_perm = mock_permissions(false, true)

        @perms = [@public_perm, @perm1, @global_perm, @perm2]
        allow(Redmine::AccessControl).to receive(:permissions).and_return(@perms)
        allow(Redmine::AccessControl).to receive(:public_permissions).and_return([@public_perm])
        allow(Redmine::AccessControl).to receive(:global_permissions).and_return([@global_perm])
      end

      def mock_permissions(is_public, is_global)
        permission = Object.new
        allow(permission).to receive(:public?).and_return(is_public)
        allow(permission).to receive(:global?).and_return(is_global)
        permission
      end

      def create_non_member_role
        create_builtin_role 'No member', Role::BUILTIN_NON_MEMBER
      end

      def create_anonymous_role
        create_builtin_role 'Anonymous', Role::BUILTIN_ANONYMOUS
      end

      def create_builtin_role(name, const)
        Role.create(name: name, position: 0) do |role|
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
