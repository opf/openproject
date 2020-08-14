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

class CostTypesController < ApplicationController
  # Allow only admins here
  before_action :require_admin
  before_action :find_cost_type, only: [:edit, :update, :set_rate, :destroy, :restore]
  layout 'admin'

  helper :sort
  include SortHelper
  helper :cost_types
  include CostTypesHelper

  def index
    sort_init 'name', 'asc'
    sort_columns = { 'name' => "#{CostType.table_name}.name",
                     'unit' => "#{CostType.table_name}.unit",
                     'unit_plural' => "#{CostType.table_name}.unit_plural" }
    sort_update sort_columns

    @cost_types = CostType.order(sort_clause)

    unless params[:clear_filter]
      @fixed_date = Date.parse(params[:fixed_date]) rescue Date.today
      @include_deleted = params[:include_deleted]
    else
      @fixed_date = Date.today
      @include_deleted = nil
    end

    render action: 'index', layout: !request.xhr?
  end

  def edit
    render action: 'edit', layout: !request.xhr?
  end

  def update
    @cost_type.attributes = permitted_params.cost_type

    if @cost_type.save
      flash[:notice] = t(:notice_successful_update)
      redirect_back_or_default(action: 'index')
    else
      render action: 'edit', layout: !request.xhr?
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = t(:notice_locking_conflict)
  end

  def new
    @cost_type = CostType.new

    @cost_type.rates.build(valid_from: Date.today) if @cost_type.rates.empty?

    render action: 'edit', layout: !request.xhr?
  end

  def create
    @cost_type = CostType.new(permitted_params.cost_type)

    if @cost_type.save
      flash[:notice] = t(:notice_successful_update)
      redirect_back_or_default(action: 'index')
    else
      @cost_type.rates.build(valid_from: Date.today) if @cost_type.rates.empty?
      render action: 'edit', layout: !request.xhr?
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = t(:notice_locking_conflict)
  end

  def destroy
    @cost_type.deleted_at = DateTime.now
    @cost_type.default = false

    if @cost_type.save
      flash[:notice] = t(:notice_successful_lock)

      redirect_back_or_default(action: 'index')
    end
  end

  def restore
    @cost_type.deleted_at = nil
    @cost_type.default = false

    if @cost_type.save
      flash[:notice] = t(:notice_successful_restore)

      redirect_back_or_default(action: 'index')
    end
  end

  def set_rate
    today = Date.today

    rate = @cost_type.rate_at(today)
    rate ||= CostRate.new.tap do |cr|
      cr.cost_type  = @cost_type
      cr.valid_from = today
    end

    rate.rate = CostRate.parse_number_string_to_number(params[:rate])
    if rate.save
      flash[:notice] = t(:notice_successful_update)
      redirect_to action: 'index'
    else
      # FIXME: Do some real error handling here
      flash[:error] = t(:notice_something_wrong)
      redirect_to action: 'index'
    end
  end

  private

  def find_cost_type
    @cost_type = CostType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def default_breadcrumb
    if action_name == 'index'
      CostType.model_name.human(count: 2)
    else
      ActionController::Base.helpers.link_to(CostType.model_name.human(count: 2), cost_types_path)
    end
  end

  def show_local_breadcrumb
    true
  end
end
