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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Projects::StatusController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper

  before_action :find_project_by_project_id
  before_action :authorize

  def update
    change_status_action(params.fetch(:status_code).presence)
  end

  def destroy
    change_status_action(nil)
  end

  private

  def change_status_action(status_code)
    call = Projects::UpdateService
      .new(model: @project, user: current_user)
      .call(status_code:)

    if call.success?
      @project = call.result
      respond_with_update_status_button
    else
      message = t(:notice_unsuccessful_update_with_reason, reason: call.message)
      respond_with_flash_error(message:) do |format|
        fallback_responses_for(format, flash: { error: message })
      end
    end
  end

  def respond_with_update_status_button
    message = t(:notice_successful_update)

    # Some views send a size parameter to adjust the status button size, keep that in
    # mind when refreshing the component via turbo stream:
    size = params[:status_size]&.to_sym
    component_options = {
      project: @project,
      user: current_user,
      size:
    }.compact

    update_via_turbo_stream(component: Projects::StatusButtonComponent.new(**component_options))
    render_success_flash_message_via_turbo_stream(message:)
    respond_with_turbo_streams do |format|
      fallback_responses_for(format, flash: { notice: message })
    end
  end

  def fallback_responses_for(format, **)
    format.html { redirect_back_or_to(project_path(@project), **) }
  end
end
