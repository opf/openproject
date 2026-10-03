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

module OpenProject::Whiteboards
  class Engine < ::Rails::Engine
    engine_name :openproject_whiteboards

    include OpenProject::Plugins::ActsAsOpEngine

    initializer "whiteboards.feature_decisions" do
      OpenProject::FeatureDecisions.add :whiteboards,
                                        description: "Enables collaborative Excalidraw whiteboards in projects."
    end

    register "openproject-whiteboards",
             author_url: "https://www.openproject.org",
             bundled: true do
      menu :project_menu,
           :whiteboards,
           { controller: "/whiteboards", action: "index" },
           caption: :label_whiteboard_plural,
           after: :documents,
           icon: "paintbrush",
           if: ->(_) { OpenProject::FeatureDecisions.whiteboards_active? }

      project_module :whiteboards do |_map|
        permission :view_whiteboards,
                   {
                     whiteboards: %i[index show],
                     "whiteboards/refresh_tokens": %i[create]
                   },
                   permissible_on: :project,
                   visible: -> { OpenProject::FeatureDecisions.whiteboards_active? }
        permission :manage_whiteboards,
                   {
                     whiteboards: %i[create update destroy]
                   },
                   permissible_on: :project,
                   require: :loggedin,
                   dependencies: :view_whiteboards,
                   visible: -> { OpenProject::FeatureDecisions.whiteboards_active? }
      end
    end

    patches %i[Project]

    add_api_path :whiteboards do
      "#{root}/whiteboards"
    end

    add_api_path :whiteboard do |id|
      "#{root}/whiteboards/#{id}"
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::Whiteboards::WhiteboardsAPI
    end
  end
end
