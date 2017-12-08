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

require_dependency 'users_helper'

module OpenProject::GlobalRoles::Patches
  module UsersHelperPatch
    def self.included(base)
      base.prepend InstanceMethods
    end

    module InstanceMethods
      def user_settings_tabs
        tabs = super
        @global_roles ||= GlobalRole.all
        tabs << { name: 'global_roles', partial: 'users/global_roles', label: 'global_roles' }
        tabs
      end
    end
  end
end

UsersHelper.send(:include, OpenProject::GlobalRoles::Patches::UsersHelperPatch)
