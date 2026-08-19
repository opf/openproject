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

  # #show, #edit and #update have their own authorization
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

  def edit # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    # TODO: split into edit and update
    # remove code where appropriate
    if @project
      # Hourly Rate
      return deny_access unless User.current.allowed_in_project?(:edit_hourly_rates, @project)
    else
      # Default Hourly Rate
      return deny_access unless User.current.admin?
    end

    if @project.nil?
      @rates = DefaultHourlyRate.where(user_id: @user)
               .order("#{DefaultHourlyRate.table_name}.valid_from desc")
               .to_a
      @rates << @user.default_rates.build(valid_from: Time.zone.today) if @rates.empty?
    else
      @rates = @user.rates.select { |r| r.project_id == @project.id }.sort { |a, b| b.valid_from <=> a.valid_from }.to_a
      @rates << @user.rates.build(valid_from: Time.zone.today, project: @project) if @rates.empty?
    end

    render action: :edit, layout: !request.xhr?
  end

  current_menu_item :edit do
    :budgets
  end

  def update # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    # TODO: copied over from edit
    # remove code where appropriate
    if @project
      # Hourly Rate
      return deny_access unless User.current.allowed_in_project?(:edit_hourly_rates, @project)
    else
      # Default Hourly Rate
      return deny_access unless User.current.admin?
    end

    if params.include? "user"
      update_rates @user,
                   @project,
                   permitted_params.user_rates[:new_rate_attributes],
                   permitted_params.user_rates[:existing_rate_attributes]
    else
      delete_rates @user, @project
    end

    if @user.save
      flash[:notice] = t(:notice_successful_update)
      if @project.nil?
        redirect_back_or_default(edit_principal_rates_path)
      else
        redirect_back_or_default({ action: "show", id: @user, project_id: @project })
      end
    else
      if @project.nil?
        @rates = @user.default_rates
        @rates << @user.default_rates.build(valid_from: Time.zone.today) if @rates.empty?
      else
        @rates = @user
                 .rates
                 .select { |r| r.project_id == @project.id }
                 .sort { |a, b| b.valid_from || Time.zone.today <=> a.valid_from || Time.zone.today }
        @rates << @user.rates.build(valid_from: Time.zone.today, project: @project) if @rates.empty?
      end
      render action: :edit, layout: !request.xhr?
    end
  end

  private

  def update_rates(user, project, added_rates, changed_rates)
    user.add_rates(project, added_rates)
    user.set_existing_rates(project, changed_rates)
  end

  def delete_rates(user, project)
    if project.present?
      user.rates.where(project:).delete_all
    else
      user.default_rates.delete_all
    end
  end

  def find_project
    @project = Project.visible.find(params.expect(:project_id))
  end

  # Rates hang off users and placeholder users alike, so the lookup is over
  # principals and the type is checked rather than assumed.
  def find_user
    @user = if params[:id].blank?
              User.current
            elsif @project
              principals_with_rates.in_project(@project).find(params.expect(:id))
            else
              principals_with_rates.find(params.expect(:id))
            end
  end

  def principals_with_rates
    Principal.visible.where(type: %w[User PlaceholderUser])
  end

  def edit_principal_rates_path
    if @user.is_a?(PlaceholderUser)
      edit_placeholder_user_path(@user, tab: :rates)
    else
      edit_user_path(@user, tab: :rates)
    end
  end
end
