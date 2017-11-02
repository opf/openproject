# OpenProject Avatars plugin
#
# Copyright (C) 2017  OpenProject GmbH
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

module OpenProject::Avatars
  module Patches
    module UsersHelperPatch
      def self.included(base) # :nodoc:
        base.prepend(InstanceMethods)
        base.class_eval do
          alias_method :user_settings_tabs_without_avatar, :user_settings_tabs
          alias_method :user_settings_tabs, :user_settings_tabs_with_avatar
        end
      end

      module InstanceMethods
        def user_settings_tabs_with_avatar
          tabs = user_settings_tabs_without_avatar
          if ::OpenProject::Avatars::AvatarManager.avatars_enabled?
            tabs << { name: 'avatar', partial: 'avatars/users/avatar_tab', label: :label_avatar }
          end

          tabs
        end
      end
    end
  end
end
