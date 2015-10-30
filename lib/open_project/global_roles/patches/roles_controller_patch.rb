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
          # we have to duplicate unpatched behaviour here in order to set the parameters for the overwritten views
          @role = Role.new(permitted_params.role? || { permissions: Role.non_member.permissions })
          @member_permissions = (@role.setable_permissions || @permissions)
          @global_permissions = GlobalRole.setable_permissions
          create_without_global_roles
        end
     end

      private

      def create_global_role
        @role = GlobalRole.new permitted_params.role
        if @role.save
          flash[:notice] = l(:notice_successful_create)
          redirect_to action: 'index'
        else
          @roles = Role.all order: 'builtin, position'
          @member_permissions = Role.new.setable_permissions
          @global_permissions = GlobalRole.setable_permissions
          render template: 'roles/new'
        end
      end
    end
  end
end

RolesController.send(:include, OpenProject::GlobalRoles::Patches::RolesControllerPatch)
