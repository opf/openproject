# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::Avatars
  class Engine < ::Rails::Engine
    engine_name :openproject_avatars

    include OpenProject::Plugins::ActsAsOpEngine

    initializer "avatars.settings_search" do
      ::Settings::Pages.draw do
        page :avatars, menu_item: :user_avatars do
          %i[enable_gravatars enable_local_avatars].each do |name|
            setting :plugin_openproject_avatars, field: "settings[#{name}]", label: :"avatars.settings.#{name}"
          end
        end
      end
    end

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
             bundled: true

    add_api_endpoint "API::V3::Users::UsersAPI", :id do
      mount ::API::V3::Users::UserAvatarAPI
    end

    add_api_endpoint "API::V3::Groups::GroupsAPI", :id do
      mount ::API::V3::Groups::GroupAvatarAPI
    end

    config.to_prepare do
      OpenProject::Avatars::Hooks
    end
  end
end
