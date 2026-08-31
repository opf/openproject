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

class Users::NonWorkingTimesController < ApplicationController
  include WorkingTimesAuthorization
  include OpTurbo::ComponentStream

  layout "admin"

  authorization_checked! :new, :create, :edit, :update, :destroy, :working_days_preview

  before_action :find_user
  before_action :authorize_manage_working_times
  before_action :find_non_working_time, only: %i[edit update destroy]

  def new
    @non_working_time = @user.non_working_times.build(prefilled_params)

    respond_with_dialog(
      Users::NonWorkingTimes::DialogComponent.new(user: @user, non_working_time: @non_working_time)
    )
  end

  def edit
    respond_with_dialog(
      Users::NonWorkingTimes::DialogComponent.new(user: @user, non_working_time: @non_working_time)
    )
  end

  def create
    call = UserNonWorkingTimes::CreateService
             .new(user: current_user)
             .call(**non_working_time_params, user: @user)

    if call.success?
      close_dialog_via_turbo_stream(Users::NonWorkingTimes::DialogComponent::DIALOG_ID)
      reload_page_via_turbo_stream
    else
      update_via_turbo_stream(
        component: Users::NonWorkingTimes::FormComponent.new(user: @user, non_working_time: call.result),
        status: :unprocessable_entity
      )
    end

    respond_with_turbo_streams
  end

  def update
    call = UserNonWorkingTimes::UpdateService
             .new(model: @non_working_time, user: current_user)
             .call(**non_working_time_params)

    if call.success?
      close_dialog_via_turbo_stream(Users::NonWorkingTimes::DialogComponent::DIALOG_ID)
      reload_page_via_turbo_stream
    else
      update_via_turbo_stream(
        component: Users::NonWorkingTimes::FormComponent.new(user: @user, non_working_time: call.result),
        status: :unprocessable_entity
      )
    end

    respond_with_turbo_streams
  end

  def destroy
    call = UserNonWorkingTimes::DeleteService
             .new(model: @non_working_time, user: current_user)
             .call

    if call.success?
      reload_page_via_turbo_stream
    else
      render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.join(", "))
    end

    respond_with_turbo_streams
  end

  def working_days_preview
    start_date = Date.parse(params[:start_date])
    end_date   = Date.parse(params[:end_date])
    nwt = @user.non_working_times.build(start_date:, end_date:)

    render json: { working_days: nwt.working_days_count }
  rescue ArgumentError, TypeError
    head :bad_request
  end

  private

  def find_user
    @user = User.visible.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_non_working_time
    @non_working_time = @user.non_working_times.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def non_working_time_params
    params.expect(user_non_working_time: %i[start_date end_date])
  end

  def prefilled_params
    params.permit(:start_date, :end_date)
  end
end
