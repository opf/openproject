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

class Projects::Settings::VersionsController < Projects::SettingsController
  menu_item :settings_versions

  def show
    @query = build_query
    @versions = @query.results.merge(@project.shared_versions)

    render layout: !turbo_frame_request?
  end

  private

  def build_query
    query = ParamsToQueryService
      .new(Version, current_user, query_class: Queries::Versions::VersionQuery)
      .call(params)

    apply_default_status_filter_and_sort(query)

    query
  end

  def apply_default_status_filter_and_sort(query)
    status_filter = query.filters.find { |f| f.name == :status }
    query.where(:status, Queries::Operators::Equals.symbol, ["open"]) if status_filter.nil?
  end
end
