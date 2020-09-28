#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module GlobalRoles
    module PluginSpecHelper
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
        @stashed_permissions = OpenProject::AccessControl.permissions.dup
        OpenProject::AccessControl.permissions.clear
      end

      def restore_access_control_permissions
        OpenProject::AccessControl.instance_variable_set(:@permissions, @stashed_permissions)
      end
    end
  end
end
