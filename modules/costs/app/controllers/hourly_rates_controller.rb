#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class HourlyRatesController < ApplicationController
  helper :users
  helper :sort
  include SortHelper
  helper :hourly_rates
  include HourlyRatesHelper

  before_action :find_user, only: [:show, :edit, :update, :set_rate]

  before_action :find_optional_project, only: [:show, :edit, :update]
  before_action :find_project, only: [:set_rate]

  # #show, #edit have their own authorization
  before_action :authorize, except: [:show, :edit, :update]

  # TODO: this should be an index
  def show
    if @project
      return deny_access unless User.current.allowed_to?(:view_hourly_rates, @project, for: @user)

      @rates = HourlyRate.where(user_id: @user, project_id: @project)
               .order("#{HourlyRate.table_name}.valid_from desc")
    else
      @rates = HourlyRate.history_for_user(@user)
      @rates_default = @rates.delete(nil)
    end
  end

  def edit
    # TODO: split into edit and update
    # remove code where appropriate
    if @project
      # Hourly Rate
      return deny_access unless User.current.allowed_to?(:edit_hourly_rates, @project)
    else
      # Default Hourly Rate
      return deny_access unless User.current.admin?
    end

    if @project.nil?
      @rates = DefaultHourlyRate.where(user_id: @user)
               .order("#{DefaultHourlyRate.table_name}.valid_from desc")
               .to_a
      @rates << @user.default_rates.build(valid_from: Date.today) if @rates.empty?
    else
      @rates = @user.rates.select { |r| r.project_id == @project.id }.sort { |a, b| b.valid_from <=> a.valid_from }.to_a
      @rates << @user.rates.build(valid_from: Date.today, project: @project) if @rates.empty?
    end

    render action: 'edit', layout: !request.xhr?
  end

  current_menu_item :edit do
    :cost_objects
  end

  def update
    # TODO: copied over from edit
    # remove code where appropriate
    if @project
      # Hourly Rate
      return deny_access unless User.current.allowed_to?(:edit_hourly_rates, @project)
    else
      # Default Hourly Rate
      return deny_access unless User.current.admin?
    end

    if params.include? 'user'
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
        redirect_back_or_default(controller: 'users', action: 'edit', id: @user)
      else
        redirect_back_or_default(action: 'show', id: @user, project_id: @project)
      end
    else
      if @project.nil?
        @rates = @user.default_rates
        @rates << @user.default_rates.build(valid_from: Date.today) if @rates.empty?
      else
        @rates = @user
                 .rates
                 .select { |r| r.project_id == @project.id }
                 .sort { |a, b| b.valid_from || Date.today <=> a.valid_from || Date.today }
        @rates << @user.rates.build(valid_from: Date.today, project: @project) if @rates.empty?
      end
      render action: 'edit', layout: !request.xhr?
    end
  end

  def set_rate
    today = Date.today

    rate = @user.rate_at(today, @project)
    rate = HourlyRate.new if rate.nil? || rate.valid_from != today

    rate.tap do |hr|
      hr.project    = @project
      hr.user       = @user
      hr.valid_from = today
      hr.rate = parse_number_string_to_number(params[:rate])
    end

    if rate.save
      if request.xhr?
        render :update do |page|
          page.replace_html "rate_for_#{@user.id}", link_to(number_to_currency(rate.rate), action: 'edit', id: @user, project_id: @project)
        end
      else
        flash[:notice] = t(:notice_successful_update)
        redirect_to action: 'index'
      end
    end
  end

  private

  def update_rates(user, project, added_rates, changed_rates)
    user.add_rates(project, added_rates)
    user.set_existing_rates(project, changed_rates)
  end

  def delete_rates(user, project)
    if project.present?
      user.rates.delete_all
    else
      user.default_rates.delete_all
    end
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = params[:project_id].blank? ? nil : Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_user
    @user = params[:id] ? User.find(params[:id]) : User.current
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
