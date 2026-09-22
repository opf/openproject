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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "open_project/plugins"

module OpenProject::StrikezoneFrank
  class Engine < ::Rails::Engine
    engine_name :openproject_strikezone_frank

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-strikezone_frank",
             author_url: "https://www.openproject.org",
             bundled: true

    assets %w[
      strikezone_frank/logo-white.svg
      strikezone_frank/logo-black.svg
      strikezone_frank/icon.svg
    ]

    # Load after OpenProject::Hook is available. Matching other plugins, this
    # runs on reload in development as well.
    config.to_prepare do
      require "open_project/strikezone_frank/hooks"

      # Menus are registered at boot. After the dedicated Frank page was
      # removed, drop leftover items so a reloaded process cannot generate
      # URLs for the deleted embeds route.
      %i[top_menu global_menu project_menu].each do |menu_name|
        Redmine::MenuManager.map(menu_name) { |menu| menu.delete(:frank_ai) }
      end
    end
  end
end
