#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class IssuesController < ApplicationController
  include OpTurbo::ComponentStream

  before_action :set_issue, only: %i[edit update destroy edit_resolution resolve reopen]
  before_action :set_work_package

  def open
    render layout: false
  end

  def closed
    render layout: false
  end

  def new
    @issue = Issue.new(work_package: @work_package)

    render layout: false
  end

  def create
    @issue = Issue.new(issue_params.merge(work_package: @work_package, author: User.current))

    if @issue.save
      redirect_to open_work_package_issues_path(@work_package)
    else
      # simply rendering the new view again as a turbo-frame messes up the src attribute of the frame
      # using turbo-stream instead as a quick fix
      update_via_turbo_stream(
        component: WorkPackageTab::Issues::FormComponent.new(issue: @issue)
      )

      respond_with_turbo_streams
    end
  end

  def edit
    render layout: false
  end

  def update
    if @issue.update(issue_params)
      redirect_to open_work_package_issues_path(@work_package)
    else
      # simply rendering the new view again as a turbo-frame messes up the src attribute of the frame
      # using turbo-stream instead as a quick fix
      update_via_turbo_stream(
        component: WorkPackageTab::Issues::FormComponent.new(issue: @issue)
      )

      respond_with_turbo_streams
    end
  end

  def destroy
    if @issue.destroy
      update_via_turbo_stream(
        component: WorkPackageTab::Issues::ListComponent.new(work_package: @work_package)
      )

      respond_with_turbo_streams
    end
  end

  def edit_resolution
    render layout: false
  end

  def resolve
    if @issue.resolve(User.current, issue_params[:resolution])
      redirect_to open_work_package_issues_path(@work_package)
    else
      # simply rendering the new view again as a turbo-frame messes up the src attribute of the frame
      # using turbo-stream instead as a quick fix
      update_via_turbo_stream(
        component: WorkPackageTab::Issues::ResolveComponent.new(issue: @issue)
      )

      respond_with_turbo_streams
    end
  end

  def reopen
    if @issue.reopen # keep the former resolution in place
      redirect_to open_work_package_issues_path(@work_package)
    end
  end

  private

  def set_work_package
    @work_package = WorkPackage.find(params[:work_package_id])
  end

  def set_issue
    @issue = Issue.find(params[:id])
  end

  def issue_params
    params.require(:issue).permit(:description, :issue_type, :resolution)
  end
end
