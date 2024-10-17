# OpenProject Avatars plugin
#
# Copyright (C) the OpenProject GmbH
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
  class Engine < ::Rails::Engine
    engine_name :openproject_avatars

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-avatars",
             author_url: "https://www.openproject.org",
             settings: {
               default: {
                 enable_gravatars: !Rails.env.test?,
                 enable_local_avatars: !Rails.env.test?
               },
               partial: "settings/openproject_avatars",
               breadcrumb_elements: -> { [{ href: admin_settings_users_path, text: I18n.t(:label_user_and_permission) }] },
               menu_item: :user_avatars
             },
             bundled: true do
      add_menu_item :my_menu, :avatar,
                    { controller: "/avatars/my_avatar", action: "show" },
                    caption: ->(*) { I18n.t("avatars.label_avatar") },
                    if: ->(*) { ::OpenProject::Avatars::AvatarManager::avatars_enabled? },
                    icon: "image"
    end

    add_api_endpoint "API::V3::Users::UsersAPI", :id do
      mount ::API::V3::Users::UserAvatarAPI
    end

    add_tab_entry :user,
                  name: "avatar",
                  partial: "avatars/users/avatar_tab",
                  path: ->(params) { edit_user_path(params[:user], tab: :avatar) },
                  label: :label_avatar,
                  only_if: ->(*) { User.current.admin? && ::OpenProject::Avatars::AvatarManager.avatars_enabled? }
  end
end
