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
      menu :my_menu,
           :avatar,
           { controller: "/avatars/my_avatar", action: "show" },
           after: :account,
           caption: :label_avatar,
           icon: "person"
    end

    add_api_endpoint "API::V3::Users::UsersAPI", :id do
      mount ::API::V3::Users::UserAvatarAPI
    end

    add_api_endpoint "API::V3::Groups::GroupsAPI", :id do
      mount ::API::V3::Groups::GroupAvatarAPI
    end

    add_tab_entry :user,
                  name: "avatar",
                  partial: "avatars/users/avatar_section",
                  path: ->(params) { edit_user_path(params[:user], tab: :avatar) },
                  label: :label_avatar,
                  only_if: ->(*) { User.current.admin? }

    add_tab_entry :group,
                  name: "avatar",
                  partial: "avatars/groups/avatar_section",
                  path: ->(params) { edit_group_path(params[:group], tab: :avatar) },
                  label: :label_avatar
  end
end
