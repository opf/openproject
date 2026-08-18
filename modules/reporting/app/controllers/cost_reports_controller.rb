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

# Reports saved before they became CostReport records are still linked to by
# their old cost_queries id, which the converted report carries along.
class CostReportsController < ApplicationController
  before_action :load_and_authorize_in_optional_project

  def index
    redirect_to reports_path
  end

  def show
    report = CostReport.visible(current_user).for_legacy_cost_query_id(params[:id])

    return render_404 if report.nil?

    redirect_to report_path(report), status: :moved_permanently
  end

  private

  def reports_path
    if @project
      project_reporting_cost_reports_path(@project)
    else
      global_reporting_cost_reports_path
    end
  end

  def report_path(report)
    if @project
      project_reporting_cost_report_path(@project, report)
    else
      reporting_cost_report_path(report)
    end
  end
end
