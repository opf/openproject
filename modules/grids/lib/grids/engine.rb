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

module Grids
  class Engine < ::Rails::Engine
    engine_name :grids

    include OpenProject::Plugins::ActsAsOpEngine

    add_api_path :attachments_by_grid do |id|
      "#{root}/grids/#{id}/attachments"
    end

    initializer "grids.permissions" do
      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.permission(:view_project)
          .controller_actions
          .push(
            "grids/widgets/project_statuses/show",
            "grids/widgets/descriptions/show",
            "grids/widgets/subitems/show"
          )

        OpenProject::AccessControl.permission(:edit_project)
          .controller_actions
          .push(
            "grids/widgets/project_statuses/update"
          )

        OpenProject::AccessControl.permission(:view_news)
          .controller_actions
          .push(
            "grids/widgets/news/show"
          )

        OpenProject::AccessControl.permission(:view_members)
          .controller_actions
          .push(
            "grids/widgets/members/show"
          )
      end
    end

    config.to_prepare do
      Queries::Register.register(Grids::Query) do
        filter Grids::Filters::ScopeFilter
      end
    end
  end
end
