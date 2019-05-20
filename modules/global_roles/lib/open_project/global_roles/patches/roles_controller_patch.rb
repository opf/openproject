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
      base.prepend InstanceMethods

      base.class_eval do
        before_action :define_global_permissions
      end
    end

    module InstanceMethods
      def create
        if params['global_role']
          create_global_role
        else
          super
        end
      end

      private

      def define_global_permissions
        @global_permissions = group_permissions_by_module(GlobalRole.setable_permissions)
      end

      def create_global_role
        @role = GlobalRole.new permitted_params.role
        if @role.save
          flash[:notice] = l(:notice_successful_create)
          redirect_to action: 'index'
        else
          define_setable_permissions
          @roles = Role.order(Arel.sql('builtin, position'))
          render template: 'roles/new'
        end
      end
    end
  end
end

RolesController.send(:include, OpenProject::GlobalRoles::Patches::RolesControllerPatch)
