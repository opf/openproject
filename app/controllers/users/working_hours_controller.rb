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

class Users::WorkingHoursController < ApplicationController
  include WorkingTimesAuthorization
  include OpTurbo::ComponentStream

  layout "admin"

  authorization_checked! :new, :edit, :create, :update, :destroy

  before_action :find_user
  before_action :authorize_manage_working_times
  before_action :find_working_hours, only: %i[edit update destroy]
  before_action :authorize_working_hours_create, only: %i[new create]
  before_action :authorize_working_hours_edit, only: %i[edit update]
  before_action :authorize_working_hours_delete, only: %i[destroy]

  def new
    @user_working_hours = if current_context?
                            duplicate_current_working_hours(@user)
                          else
                            build_working_hours_from_system_settings(@user)
                          end

    respond_with_dialog(
      Users::WorkingHours::DialogComponent.new(user: @user, working_hours: @user_working_hours,
                                               show_valid_from: !current_context?)
    )
  end

  def edit
    respond_with_dialog(
      Users::WorkingHours::DialogComponent.new(user: @user, working_hours: @user_working_hours,
                                               show_valid_from: !current_context?)
    )
  end

  def create
    call = UserWorkingHours::CreateService
             .new(user: current_user)
             .call(working_hours_params.merge(user: @user))

    if call.success?
      close_dialog_via_turbo_stream(Users::WorkingHours::DialogComponent::DIALOG_ID)
      reload_page_via_turbo_stream
    else
      update_via_turbo_stream(
        component: Users::WorkingHours::FormComponent.new(user: @user, working_hours: call.result,
                                                          show_valid_from: !current_context?),
        status: :unprocessable_entity
      )
    end

    respond_with_turbo_streams
  end

  def update
    call = UserWorkingHours::UpdateService
             .new(model: @user_working_hours, user: current_user)
             .call(working_hours_params)

    if call.success?
      close_dialog_via_turbo_stream(Users::WorkingHours::DialogComponent::DIALOG_ID)
      reload_page_via_turbo_stream
    else
      update_via_turbo_stream(
        component: Users::WorkingHours::FormComponent.new(user: @user, working_hours: call.result,
                                                          show_valid_from: !current_context?),
        status: :unprocessable_entity
      )
    end

    respond_with_turbo_streams
  end

  def destroy
    call = UserWorkingHours::DeleteService
             .new(model: @user_working_hours, user: current_user)
             .call

    if call.success?
      reload_page_via_turbo_stream
    else
      render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.join(", "))
    end

    respond_with_turbo_streams
  end

  private

  def current_context?
    params[:current] == "true"
  end

  def authorize_working_hours_create
    deny_access unless UserWorkingHours::CreateContract.can_create?(user: current_user, target_user: @user)
  end

  def authorize_working_hours_edit
    deny_access unless UserWorkingHours::UpdateContract.can_update?(user: current_user, working_hours: @user_working_hours)
  end

  def authorize_working_hours_delete
    deny_access unless UserWorkingHours::DeleteContract.can_delete?(user: current_user, target_user: @user)
  end

  def find_user
    @user = User.visible.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_working_hours
    @user_working_hours = @user.working_hours.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def working_hours_params
    params.expect(
      user_working_hours: %i[valid_from
                             monday_hours
                             tuesday_hours
                             wednesday_hours
                             thursday_hours
                             friday_hours
                             saturday_hours
                             sunday_hours
                             availability_factor]
    ).tap { Rails.logger.debug(it.to_h) }
  end

  def duplicate_current_working_hours(user)
    current = user.working_hours.current
    return build_working_hours_from_system_settings(user) unless current

    day_attrs = UserWorkingHours::DAYS.to_h { |day| ["#{day}_hours", current.public_send("#{day}_hours")] }

    UserWorkingHours.new(
      user:,
      availability_factor: current.availability_factor,
      valid_from: Date.current,
      **day_attrs
    )
  end

  def build_working_hours_from_system_settings(user)
    working_day_names = Setting.working_day_names
    hours_per_day     = Setting.hours_per_day

    day_attrs = UserWorkingHours::DAYS.to_h do |day|
      ["#{day}_hours", working_day_names.include?(day) ? hours_per_day : 0]
    end

    UserWorkingHours.new(
      user: user,
      availability_factor: 100,
      valid_from: Date.current,
      **day_attrs
    )
  end
end
