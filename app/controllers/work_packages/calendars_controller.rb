#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::CalendarsController < ApplicationController
  menu_item :calendar
  before_action :find_optional_project

  rescue_from Query::StatementInvalid, with: :query_statement_invalid

  include QueriesHelper
  include SortHelper

  def index
    @year, @month = set_timeframe(params)

    @calendar = new_calendar(@year, @month)

    retrieve_query
    @query.group_by = nil

    @calendar.events = events_in_timeframe_and_filter(@query, @calendar)

    render layout: !request.xhr?
  end

  private

  def default_breadcrumb
    l(:label_calendar)
  end

  def events_in_timeframe_and_filter(query, calendar)
    if query.valid?
      events = work_packages_in_timeframe(query, calendar)

      events += versions_in_timeframe(query, calendar)

      events
    else
      []
    end
  end

  def work_packages_in_timeframe(query, calendar)
    query.results(
      conditions: [
        "((#{WorkPackage.table_name}.start_date BETWEEN ? AND ?) OR
          (#{WorkPackage.table_name}.due_date BETWEEN ? AND ?))",
        calendar.startdt, calendar.enddt,
        calendar.startdt, calendar.enddt
      ]
    ).work_packages
  end

  def versions_in_timeframe(query, calendar)
    query.results(
      conditions: [
        "#{Version.table_name}.effective_date BETWEEN ? AND ?",
        calendar.startdt,
        calendar.enddt
      ]
    ).versions
  end

  def set_timeframe(params)
    if valid_year_string?(params[:year])
      year = params[:year].to_i

      if valid_month_string?(params[:month])
        month = params[:month].to_i
      end
    end

    year ||= Date.today.year
    month ||= Date.today.month

    [year, month]
  end

  def valid_year_string?(year)
    year && year.to_i > 1900
  end

  def valid_month_string?(month)
    month && month.to_i > 0 && month.to_i < 13
  end

  def new_calendar(year, month)
    Redmine::Helpers::Calendar.new(Date.civil(year, month, 1), current_language, :month)
  end
end
