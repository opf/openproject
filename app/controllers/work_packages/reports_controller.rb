#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::ReportsController < ApplicationController
  menu_item :summary_field, only: [:report, :report_details]
  before_filter :find_project_by_project_id, :authorize

  def report
    reports_service = Reports::ReportsService.new(@project)

    @type_report      = reports_service.report_for('type')
    @priority_report  = reports_service.report_for('priority')
    @assignee_report  = reports_service.report_for('assigned_to')
    @responsible_report = reports_service.report_for('responsible')
    @author_report    = reports_service.report_for('author')
    @version_report   = reports_service.report_for('version')
    @subproject_report = reports_service.report_for('subproject')
    @category_report  = reports_service.report_for('category')
  end

  def report_details
    @report = Reports::ReportsService.new(@project)
              .report_for(params[:detail])

    respond_to do |format|
      if @report
        format.html {}
      else
        format.html { redirect_to report_project_work_packages_path(@project) }
      end
    end
  end

  private

  def default_breadcrumb
    l(:label_summary)
  end
end
