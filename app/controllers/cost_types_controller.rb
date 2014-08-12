#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class CostTypesController < ApplicationController
  unloadable

  # Allow only admins here
  before_filter :require_admin
  before_filter :find_cost_type, :only => [:edit, :update, :set_rate, :toggle_delete]

  helper :sort
  include SortHelper
  helper :cost_types
  include CostTypesHelper

  def index
    sort_init 'name', 'asc'
    sort_columns = { "name" => "#{CostType.table_name}.name",
                     "unit" => "#{CostType.table_name}.unit",
                     "unit_plural" => "#{CostType.table_name}.unit_plural" }
    sort_update sort_columns

    @cost_types = CostType.find :all, :order => sort_clause

    unless params[:clear_filter]
      @fixed_date = Date.parse(params[:fixed_date]) rescue Date.today
      @include_deleted = params[:include_deleted]
    else
      @fixed_date = Date.today
      @include_deleted = nil
    end

    render :action => 'index', :layout => !request.xhr?
  end

  def edit
    render :action => "edit", :layout => !request.xhr?
  end

  def update
    @cost_type.attributes = permitted_params.cost_type

    if @cost_type.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default(:action => 'index')
    else
      render :action => "edit", :layout => !request.xhr?
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
  end

  def new
    @cost_type = CostType.new()

    @cost_type.rates.build({:valid_from => Date.today}) if @cost_type.rates.empty?

    render :action => "edit", :layout => !request.xhr?
  end

  def create
    @cost_type = CostType.new(permitted_params.cost_type)

    if @cost_type.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default(:action => 'index')
    else
      @cost_type.rates.build({:valid_from => Date.today}) if @cost_type.rates.empty?
      render :action => "edit", :layout => !request.xhr?
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
  end

  def toggle_delete
    @cost_type.deleted_at = @cost_type.deleted_at ?  nil : DateTime.now()
    @cost_type.default = false

    if @cost_type.save
      flash[:notice] = @cost_type.deleted_at ? l(:notice_successful_delete) : l(:notice_successful_restore)

      redirect_back_or_default(:action => 'index')
    end
  end

  def set_rate
    today = Date.today

    rate = @cost_type.rate_at(today)
    rate ||= CostRate.new.tap do |cr|
      cr.cost_type  = @cost_type
      cr.valid_from = today
    end

    rate.rate = clean_currency(params[:rate])
    if rate.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      # FIXME: Do some real error handling here
      flash[:error] = l(:notice_something_wrong)
      redirect_to :action => 'index'
    end
  end

private
  def find_cost_type
    @cost_type = CostType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def default_breadcrumb
    CostType.model_name.human(:count=>2)
  end
end
