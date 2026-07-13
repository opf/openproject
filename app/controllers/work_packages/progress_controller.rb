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

class WorkPackages::ProgressController < ApplicationController
  include OpTurbo::ComponentStream
  include FlashMessagesHelper
  include WorkPackages::Progress::ModalParams

  layout false
  authorization_checked! :new, :edit, :preview, :create, :update

  def new
    make_fake_initial_work_package
    set_progress_attributes_to_work_package

    render_modal
  end

  def edit
    find_work_package
    set_progress_attributes_to_work_package

    render_modal
  end

  def preview
    if params[:work_package_id]
      find_work_package
    else
      make_fake_initial_work_package
    end

    set_progress_attributes_to_work_package
    render_modal
  end

  def create
    make_fake_initial_work_package
    service_call = set_progress_attributes_to_work_package

    if service_call.errors
                   .map(&:attribute)
                   .intersect?(ERROR_PRONE_ATTRIBUTES)
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: progress_modal_component,
            method: "morph"
          )

          # Bundle 422 status code into stream response so
          # Angular has context as to the success or failure of
          # the request in order to fetch the new set of Work Package
          # attributes in the ancestry solely on success.
          respond_with_turbo_streams(status: :unprocessable_entity)
        end
      end
    else
      render json: { estimatedTime: formatted_duration(@work_package.estimated_hours),
                     remainingTime: formatted_duration(@work_package.remaining_hours),
                     percentageDone: @work_package.done_ratio }
    end
  end

  def update
    find_work_package
    service_call = WorkPackages::UpdateService
                     .new(user: current_user,
                          model: @work_package)
                     .call(work_package_progress_params)

    if service_call.success?
      head :ok
    else
      respond_to do |format|
        format.turbo_stream do
          # errors not visible from progress modal fields are rendered in a flash message
          render_error_flash_message_via_turbo_stream(message: extra_error_messages(service_call))

          update_via_turbo_stream(
            component: progress_modal_component,
            method: "morph"
          )

          # Bundle 422 status code into stream response so
          # Angular has context as to the success or failure of
          # the request in order to fetch the new set of Work Package
          # attributes in the ancestry solely on success.
          respond_with_turbo_streams(status: :unprocessable_entity)
        end
      end
    end
  end

  private

  def render_modal
    render :modal,
           locals: {
             progress_modal_component:
           }
  end

  def find_work_package
    @work_package = WorkPackage.visible.find(params[:work_package_id])
  end

  def make_fake_initial_work_package
    initial_params = params["work_package"]["initial"]
      .slice(*%w[estimated_hours remaining_hours done_ratio status_id])
      .permit!
    @work_package = WorkPackage.new(initial_params)
    @work_package.clear_changes_information
  end

  def formatted_duration(hours)
    API::V3::Utilities::DateTimeFormatter.format_duration_from_hours(hours, allow_nil: true)
  end
end
