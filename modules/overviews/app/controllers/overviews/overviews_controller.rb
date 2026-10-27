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

module ::Overviews
  class OverviewsController < ::Grids::BaseInProjectController
    before_action :jump_to_project_menu_item, only: [:show] # rubocop:disable Rails/LexicallyScopedActionFilter

    menu_item :overview

    def project_custom_fields_sidebar
      render :project_custom_fields_sidebar, layout: false
    end

    def project_life_cycle_sidebar
      render :project_life_cycle_sidebar, layout: false
    end

    def jump_to_project_menu_item
      # try to redirect to the requested menu item
      redirect_to_project_menu_item(@project, params[:jump]) if params[:jump]
    end
  end
end
