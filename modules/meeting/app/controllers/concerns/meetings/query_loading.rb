# frozen_string_literal: true

# -- copyright
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
# ++

module Meetings
  module QueryLoading
    private

    def build_meeting_query
      query = ParamsToQueryService.new(Meeting, current_user).call(params)
      query.where("project_id", "=", @project.id) if @project
      apply_default_filter_if_none_given(query)
      apply_default_time_filter_and_sort(query)
      query
    end

    def apply_default_time_filter_and_sort(query)
      time_filter = query.filters.find { |f| f.name == :time }

      if time_filter.nil?
        # Only default to upcoming on the initial, unfiltered view
        query.where("time", Queries::Operators::Upcoming.symbol, []) unless params.key?(:filters)
        query.order(start_time: :asc)
      elsif time_filter.past? && query.orders.none?
        query.order(start_time: :desc)
      end
    end

    def apply_default_filter_if_none_given(query)
      return if params.key?(:filters)

      query.where("invited_user_id", "=", [User.current.id.to_s])
    end
  end
end
