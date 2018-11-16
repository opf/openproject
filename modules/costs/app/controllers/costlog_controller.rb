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

class CostlogController < ApplicationController
  menu_item :work_packages
  before_action :find_project, :authorize, only: [:edit,
                                                  :new,
                                                  :create,
                                                  :update,
                                                  :destroy]
  before_action :find_associated_objects, only: [:create,
                                                 :update]
  before_action :find_optional_project, only: [:report,
                                               :index]

  helper :sort
  include SortHelper
  helper :work_packages
  include CostlogHelper
  include PaginationHelper

  def index
    sort_init 'spent_on', 'desc'
    sort_update 'spent_on' => 'spent_on',
                'user' => 'user_id',
                'project' => "#{Project.table_name}.name",
                'work_package' => 'work_package_id',
                'cost_type' => 'cost_type_id',
                'units' => 'units',
                'costs' => 'costs'

    cond = ARCondition.new
    if @project.nil?
      cond << "project_id IN (#{Project.allowed_to(User.current, :view_cost_entries).to_sql})"
    elsif @work_package.nil?
      cond << @project.project_condition(Setting.display_subprojects_work_packages?)
    else
      root_cond = "#{WorkPackage.table_name}.root_id #{(@work_package.root_id.nil?) ? 'IS NULL' : "= #{@work_package.root_id}"}"
      cond << "#{root_cond} AND #{WorkPackage.table_name}.lft >= #{@work_package.lft} AND #{WorkPackage.table_name}.rgt <= #{@work_package.rgt}"
    end

    if @cost_type
      cond << ["#{CostEntry.table_name}.cost_type_id = ?", @cost_type.id]
    end

    retrieve_date_range
    cond << ['spent_on BETWEEN ? AND ?', @from, @to]

    respond_to do |format|
      format.html {
        @entries = CostEntry.includes(:project, :cost_type, :user, work_package: :type)
                   .merge(Project.allowed_to(User.current, :view_cost_entries))
                   .where(cond.conditions)
                   .order(sort_clause)
                   .page(page_param)
                   .per_page(per_page_param)

        render layout: !request.xhr?
      }
    end
  end

  def new
    new_default_cost_entry

    render action: 'edit'
  end

  def edit
    render_403 unless @cost_entry.try(:editable_by?, User.current)
  end

  def create
    new_default_cost_entry
    update_cost_entry_from_params

    if !@cost_entry.creatable_by?(User.current)

      render_403

    elsif @cost_entry.save

      flash[:notice] = t(:notice_cost_logged_successfully)
      redirect_back_or_default action: 'index', work_package_id: @cost_entry.work_package.id

    else
      render action: 'edit'
    end
  end

  def update
    update_cost_entry_from_params

    if !@cost_entry.editable_by?(User.current)

      render_403

    elsif @cost_entry.save

      flash[:notice] = t(:notice_successful_update)
      redirect_back_or_default action: 'index', work_package_id: @cost_entry.work_package.id

    else
      render action: 'edit'
    end
  end

  verify method: :delete, only: :destroy, render: { nothing: true, status: :method_not_allowed }
  def destroy
    render_404 and return unless @cost_entry
    render_403 and return unless @cost_entry.editable_by?(User.current)
    @cost_entry.destroy
    flash[:notice] = t(:notice_successful_delete)

    if request.referer =~ /cost_reports/
      redirect_to controller: '/cost_reports', action: :index
    else
      redirect_to :back
    end
  rescue ::ActionController::RedirectBackError
    redirect_to action: 'index', work_package_id: @cost_entry.work_package.id
  end

  def get_cost_type_unit_plural
    @cost_type = CostType.find(params[:cost_type_id]) unless params[:cost_type_id].empty?

    if request.xhr?
      render partial: 'cost_type_unit_plural', layout: false
    end
  end

  private

  def find_project
    # copied from timelog_controller.rb
    if params[:id]
      @cost_entry = CostEntry.find(params[:id])
      @project = @cost_entry.project
    elsif params[:work_package_id]
      @work_package = WorkPackage.find(params[:work_package_id])
      @project = @work_package.project
    elsif params[:work_package_id]
      @work_package = WorkPackage.find(params[:work_package_id])
      @project = @work_package.project
    elsif params[:project_id]
      @project = Project.find(params[:project_id])
    else
      render_404
      return false
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    if !params[:work_package_id].blank?
      @work_package = WorkPackage.find(params[:work_package_id])
      @project = @work_package.project
    elsif !params[:work_package_id].blank?
      @work_package = WorkPackage.find(params[:work_package_id])
      @project = @work_package.project
    elsif !params[:project_id].blank?
      @project = Project.find(params[:project_id])
    end

    if !params[:cost_type_id].blank?
      @cost_type = CostType.find(params[:cost_type_id])
    end
  end

  def find_associated_objects
    user_id = cost_entry_params.delete(:user_id)
    @user = @cost_entry.present? && @cost_entry.user_id == user_id ?
              @cost_entry.user :
              User.find_by_id(user_id)

    work_package_id = cost_entry_params.delete(:work_package_id)
    @work_package = @cost_entry.present? && @cost_entry.work_package_id == work_package_id ?
               @cost_entry.work_package :
               WorkPackage.find_by_id(work_package_id)

    cost_type_id = cost_entry_params.delete(:cost_type_id)
    @cost_type = @cost_entry.present? && @cost_entry.cost_type_id == cost_type_id ?
                   @cost_entry.cost_type :
                   CostType.find_by_id(cost_type_id)
  end

  def retrieve_date_range
    # Mostly copied from timelog_controller.rb
    @free_period = false
    @from = nil
    @to = nil

    if params[:period_type] == '1' || (params[:period_type].nil? && !params[:period].nil?)
      case params[:period].to_s
      when 'today'
        @from = @to = Date.today
      when 'yesterday'
        @from = @to = Date.today - 1
      when 'current_week'
        @from = Date.today - (Date.today.cwday - 1) % 7
        @to = @from + 6
      when 'last_week'
        @from = Date.today - 7 - (Date.today.cwday - 1) % 7
        @to = @from + 6
      when '7_days'
        @from = Date.today - 7
        @to = Date.today
      when 'current_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1)
        @to = (@from >> 1) - 1
      when 'last_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1) << 1
        @to = (@from >> 1) - 1
      when '30_days'
        @from = Date.today - 30
        @to = Date.today
      when 'current_year'
        @from = Date.civil(Date.today.year, 1, 1)
        @to = Date.civil(Date.today.year, 12, 31)
      end
    elsif params[:period_type] == '2' || (params[:period_type].nil? && (!params[:from].nil? || !params[:to].nil?))
      begin; @from = params[:from].to_s.to_date unless params[:from].blank?; rescue; end
      begin; @to = params[:to].to_s.to_date unless params[:to].blank?; rescue; end
      @free_period = true
      # default
    end

    @from, @to = @to, @from if @from && @to && @from > @to
    @from ||= (CostEntry.includes([:project, :user])
                        .visible
                        .minimum(:spent_on) || Date.today) - 1
    @to ||= (CostEntry.includes([:project, :user])
                      .visible
                      .maximum(:spent_on) || Date.today)
  end

  def new_default_cost_entry
    @cost_entry = CostEntry.new.tap do |ce|
      ce.project  = @project
      ce.work_package = @work_package
      ce.user = User.current
      ce.spent_on = Date.today
      # notice that cost_type is set to default cost_type in the model
    end
  end

  def update_cost_entry_from_params
    @cost_entry.user = @user
    @cost_entry.work_package = @work_package
    @cost_entry.cost_type = @cost_type

    @cost_entry.attributes = permitted_params.cost_entry
  end

private
  def cost_entry_params
    params.require(:cost_entry).permit(:work_package_id, :spent_on, :user_id,
                                       :cost_type_id, :units, :comments)
  end
end
