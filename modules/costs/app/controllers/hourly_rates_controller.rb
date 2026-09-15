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

class HourlyRatesController < ApplicationController
  helper :users
  helper :sort
  include SortHelper

  helper :hourly_rates
  include HourlyRatesHelper

  before_action :find_optional_project, only: %i[edit update]
  before_action :find_project, only: %i[show]
  before_action :find_user, only: %i[show edit update]
  before_action :authorize_rate_management, only: %i[edit update]

  # #show authorizes itself; #edit and #update go through the rate contracts,
  # which also cover the default rates that have no project to authorize against.
  before_action :authorize, except: %i[show edit update]
  no_authorization_required! :show,
                             :edit,
                             :update

  # TODO: this should be an index
  def show
    return deny_access if @project.nil?
    return deny_access unless User.current.allowed_in_project?(:view_hourly_rates, @project)

    @rates = HourlyRate.where(user_id: @user, project_id: @project).order("#{HourlyRate.table_name}.valid_from desc")
  end

  def edit
    @rates = rates_for_form

    render action: :edit, layout: !request.xhr?
  end

  current_menu_item :edit do
    :budgets
  end

  def update
    result = ::Rates::UpdateHistoryService
               .new(user: current_user, principal: @user, project: @project)
               .call(**submitted_rate_attributes)

    if result.success?
      flash[:notice] = t(:notice_successful_update)
      redirect_back_or_default(rates_overview_target)
    else
      @rates = rates_from(result)
      render action: :edit, layout: !request.xhr?
    end
  end

  private

  # A submission without a `user` key carries no rows at all, which the service
  # reads as "every rate in this scope was removed".
  def submitted_rate_attributes
    return { new_rate_attributes: {}, existing_rate_attributes: {} } unless params.include?("user")

    { new_rate_attributes: permitted_params.user_rates[:new_rate_attributes].to_h,
      existing_rate_attributes: permitted_params.user_rates[:existing_rate_attributes].to_h }
  end

  def rates_for_form
    rates = if @project
              @user.rates.in_project(@project).newest_first.to_a
            else
              @user.default_rates.newest_first.to_a
            end

    rates << build_blank_rate if rates.empty?
    rates
  end

  # The rollback leaves the rejected input on the returned records, so the form
  # comes back filled in with the user's values and their errors.
  def rates_from(result)
    rates = result
              .all_results
              .grep(::Rate)
              .reject(&:destroyed?)
              .sort_by { |rate| rate.valid_from || Time.zone.today }
              .reverse

    rates.presence || rates_for_form
  end

  def build_blank_rate
    if @project
      @user.rates.build(valid_from: Time.zone.today, project: @project)
    else
      @user.default_rates.build(valid_from: Time.zone.today)
    end
  end

  def rates_overview_target
    if @project
      { action: "show", id: @user, project_id: @project }
    else
      edit_principal_rates_path
    end
  end

  def authorize_rate_management
    deny_access unless rate_contract_class.can_manage?(user: current_user, principal_id: @user.id, project: @project)
  end

  def rate_contract_class
    @project ? ::HourlyRates::BaseContract : ::DefaultHourlyRates::BaseContract
  end

  def find_project
    @project = Project.visible.find(params.expect(:project_id))
  end

  # Rates hang off users and placeholder users alike, so the lookup is over
  # principals rather than users.
  def find_user
    @user = if params[:id].blank?
              User.current
            elsif @project
              Principal.with_rates.in_project(@project).find(params.expect(:id))
            else
              Principal.with_rates.find(params.expect(:id))
            end
  end

  def edit_principal_rates_path
    if @user.is_a?(PlaceholderUser)
      edit_placeholder_user_path(@user, tab: :rates)
    else
      edit_user_path(@user, tab: :rates)
    end
  end
end
