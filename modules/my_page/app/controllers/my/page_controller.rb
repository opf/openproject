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

module My
  class PageController < ApplicationController
    before_action :require_login
    no_authorization_required! :show

    current_menu_item [:show] do
      :my_page
    end

    def show
      respond_to do |format|
        format.html do
          render locals: { menu_name: :global_menu, my_day: my_day?, tab: current_tab, today:, upcoming:, unplanned: }
        end
      end
    end

    private

    def my_day? = OpenProject::FeatureDecisions.my_day_active?

    def current_tab
      return "dashboard" unless my_day?

      %w[upcoming unplanned dashboard].include?(params[:tab]) ? params[:tab] : "today"
    end

    def today
      MyDay::Today.for(current_user) if current_tab == "today"
    end

    def upcoming
      MyDay::Upcoming.for(current_user) if current_tab == "upcoming"
    end

    def unplanned
      MyDay::Unplanned.for(current_user) if current_tab == "unplanned"
    end
  end
end
