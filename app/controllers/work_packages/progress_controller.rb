# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2024 the OpenProject GmbH
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

class WorkPackages::ProgressController < ApplicationController
  layout false
  before_action :set_work_package

  def edit
    render WorkPackages::Progress::ModalBodyComponent.new(@work_package)
  end

  def update
    service_call = WorkPackages::UpdateService
                     .new(user: current_user,
                          model: @work_package)
                     .call(work_package_params)

    if service_call.success?
      respond_to do |format|
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.turbo_stream do
          # Bundle 422 status code into stream response so
          # Angular has context as to the success or failure of
          # the request in order to fetch the new set of Work Package
          # attributes in the ancestry solely on success.
          render :update, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_work_package
    @work_package = WorkPackage.find(params[:work_package_id])
  end

  def work_package_params
    params.require(:work_package)
          .permit(%i[estimated_hours remaining_hours done_ratio])
  end
end
