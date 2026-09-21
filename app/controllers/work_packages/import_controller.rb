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

class WorkPackages::ImportController < ApplicationController
  menu_item :work_packages
  before_action :find_project_by_project_id, :authorize

  def show; end

  def create
    result = schedule

    if result.success?
      redirect_to import_project_work_packages_path(@project, job: result.result)
    else
      flash[:error] = result.message
      redirect_to import_project_work_packages_path(@project)
    end
  end

  def template
    send_data ::WorkPackages::Import::CSV::Template.call(project: @project),
              filename: ::WorkPackages::Import::CSV::Template::FILENAME,
              type: "text/csv; charset=utf-8"
  end

  private

  def schedule
    ::WorkPackages::Import::CSV::ScheduleService
      .new(user: current_user, project: @project)
      .call(file: params[:file], attachment_id: params[:attachment_id], dry_run: dry_run?)
  end

  def dry_run?
    ActiveModel::Type::Boolean.new.cast(params.fetch(:dry_run, true))
  end
end
