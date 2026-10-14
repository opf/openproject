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

module Planner
  # What the Planner's controllers share: the feature flag, the user's "My work" project, the view
  # and its filter. The filter is kept in the session, so that it stays while switching views and
  # while the views refresh themselves.
  module RequestContext
    extend ActiveSupport::Concern

    included do
      before_action :require_login
      before_action :require_planner
      before_action :require_planner_project
    end

    private

    def require_planner
      render_404 unless OpenProject::FeatureDecisions.planner_active?
    end

    def require_planner_project
      render_error(message: I18n.t("planner.errors.unavailable"), status: 422) unless planner_project
    end

    def planner_project
      return @planner_project if defined?(@planner_project)

      call = Planner::ProjectService.new(current_user).call
      @planner_project = call.result if call.success?
    end

    def current_view = Views.fetch(params.fetch(:view, nil))

    def planner_filter
      requested = params.fetch(:filter, nil)
      session[:planner_filter] = requested if requested.in?(View::FILTERS)

      session[:planner_filter].presence_in(View::FILTERS) || View::FILTERS.first
    end
  end
end
