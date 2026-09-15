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

class DefaultHourlyRatesController < ApplicationController
  include OpTurbo::ComponentStream

  before_action :find_principal, only: %i[new]
  before_action :find_rate, only: %i[edit update deletion_dialog destroy]
  before_action :authorize_rate_management

  no_authorization_required! :new, :create, :edit, :update, :deletion_dialog, :destroy

  def new
    @rate = DefaultHourlyRate.new(principal: @principal, valid_from: Time.zone.today)
  end

  def edit; end

  def create
    call = DefaultHourlyRates::CreateService
             .new(user: current_user)
             .call(rate_params)

    respond_to_write(call, dialog_id: HourlyRates::RateDialogComponent::DIALOG_ID)
  end

  def update
    call = DefaultHourlyRates::UpdateService
             .new(user: current_user, model: @rate)
             .call(rate_params)

    respond_to_write(call, dialog_id: HourlyRates::RateDialogComponent::DIALOG_ID)
  end

  def deletion_dialog
    respond_with_dialog(HourlyRates::DeleteDialogComponent.new(rate: @rate))
  end

  def destroy
    call = DefaultHourlyRates::DeleteService.new(user: current_user, model: @rate).call

    respond_to_write(call, dialog_id: HourlyRates::DeleteDialogComponent::DIALOG_ID)
  end

  private

  # A write either closes its dialog and hands back a freshly rendered table,
  # or leaves the dialog open with the rejected form.
  def respond_to_write(call, dialog_id:)
    @rate = call.result
    @principal ||= @rate.principal

    if call.success?
      close_dialog_via_turbo_stream(dialog_id)
      replace_via_turbo_stream(component: rate_table_component)
      replace_via_turbo_stream(component: current_rate_component)
    elsif dialog_id == HourlyRates::DeleteDialogComponent::DIALOG_ID
      render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.to_sentence)
    else
      update_via_turbo_stream(component: rate_form_component, status: :bad_request)
    end

    respond_with_turbo_streams
  end

  def rate_table_component
    HourlyRates::TableComponent.new(
      rows: DefaultHourlyRate.for_principal(@principal).newest_first,
      current_rate: @principal.current_default_rate,
      new_rate_url: new_default_hourly_rate_path(principal_id: @principal.id)
    )
  end

  def current_rate_component
    HourlyRates::CurrentRateComponent.new(rate: @principal.current_default_rate)
  end

  def rate_form_component
    HourlyRates::RateFormComponent.new(rate: @rate, form_url: rate_form_url)
  end

  def rate_form_url
    @rate.persisted? ? default_hourly_rate_path(@rate) : default_hourly_rates_path
  end

  def rate_params
    params.expect(rate: %i[valid_from rate user_id])
  end

  def find_principal
    @principal = Principal.with_rates.find(params.expect(:principal_id))
  end

  def find_rate
    @rate = DefaultHourlyRate.find(params.expect(:id))
  end

  def authorize_rate_management
    deny_access unless DefaultHourlyRates::BaseContract.can_manage?(user: current_user)
  end
end
