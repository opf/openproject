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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Links created before cost reports became CostReport records are still out
# there - in wikis and mails, and from the work package and budget pages. They
# address a report by its old cost_queries id and pass filters as
# fields[]/operators[]/values[], so both are translated to the current url.
class CostReportsController < ApplicationController
  before_action :load_and_authorize_in_optional_project

  def index
    redirect_to reports_path(legacy_query)
  end

  def show
    report = CostReport.visible(current_user).for_legacy_cost_query_id(params[:id])

    return render_404 if report.nil?

    redirect_to report_path(report, legacy_query), status: :moved_permanently
  end

  private

  def legacy_query
    filters = ::CostReports::LegacyFilters.new(operators: params[:operators],
                                               values: params[:values],
                                               rows: params.dig(:groups, :rows),
                                               columns: params.dig(:groups, :columns))

    return {} unless filters.any?

    filters.to_params.merge(params.permit(:unit).to_h.symbolize_keys)
  end

  def reports_path(query = {})
    if @project
      project_reporting_cost_reports_path(@project, query)
    else
      global_reporting_cost_reports_path(query)
    end
  end

  def report_path(report, query = {})
    if @project
      project_reporting_cost_report_path(@project, report, query)
    else
      reporting_cost_report_path(report, query)
    end
  end
end
