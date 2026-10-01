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

class Projects::ArchiveController < ApplicationController
  include OpTurbo::ComponentStream

  before_action :find_project_including_archived
  before_action :authorize, only: %i[create dialog]
  before_action :require_admin, only: [:destroy]

  def create
    change_status_action(:archive)
  end

  def destroy
    change_status_action(:unarchive)
  end

  def dialog
    respond_with_dialog Projects::ArchiveDialogComponent.new(project: @project)
  end

  private

  def find_project_including_archived
    # The visible scope filters out archived projects, but here we want to explicitly unarchive them.
    # The contracts do proper permission checks, so we can skip the visible scope here.
    @project = Project.find(params[:project_id])
  end

  def change_status_action(status)
    service_call = change_status(status)

    if !service_call.success?
      flash[:error] = t(:"error_can_not_#{status}_project",
                        errors: service_call.errors.full_messages.join(", "))
    end

    redirect_to(projects_path, status: :see_other)
  end

  def change_status(status)
    service_class(status)
      .new(user: current_user, model: @project)
      .call
  end

  def service_class(status)
    case status
    when :archive then Projects::ArchiveService
    when :unarchive then Projects::UnarchiveService
    end
  end
end
