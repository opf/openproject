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

class CostObjectsController < ApplicationController
  before_action :find_cost_object, only: [:show, :edit, :update, :copy]
  before_action :find_cost_objects, only: :destroy
  before_action :find_project, only: [
      :new, :create,
      :update_material_budget_item, :update_labor_budget_item
  ]
  before_action :find_optional_project, only: :index

  before_action :authorize_global, only: :index
  before_action :authorize, except: [
      # unrestricted actions
      :index,
      :update_material_budget_item, :update_labor_budget_item
  ]

  helper :sort
  include SortHelper
  helper :projects
  include ProjectsHelper
  helper :attachments
  include AttachmentsHelper
  helper :costlog
  include CostlogHelper
  helper :cost_objects
  include CostObjectsHelper
  include PaginationHelper

  def index
    respond_to do |format|
      format.html do
      end
      format.csv { limit = Setting.work_packages_export_limit.to_i }
    end

    sort_columns = { 'id' => "#{CostObject.table_name}.id",
                     'subject' => "#{CostObject.table_name}.subject",
                     'fixed_date' => "#{CostObject.table_name}.fixed_date"
    }

    sort_init 'id', 'desc'
    sort_update sort_columns

    @cost_objects = CostObject
        .visible(current_user)
        .order(sort_clause)
        .includes(:author)
        .where(project_id: @project.id)
        .page(page_param)
        .per_page(per_page_param)

    respond_to do |format|
      format.html do
        render action: 'index', layout: !request.xhr?
      end
      format.csv { send_data(cost_objects_to_csv(@cost_objects), type: 'text/csv; header=present', filename: 'export.csv') }
    end
  end

  def show
    @edit_allowed = User.current.allowed_to?(:edit_cost_objects, @project)
    respond_to do |format|
      format.html { render action: 'show', layout: !request.xhr? }
    end
  end

  def new
    # FIXME: I forcibly create a VariableCostObject for now. Following Ticket #5360
    @cost_object ||= VariableCostObject.new
    @cost_object.project_id = @project.id
    @cost_object.fixed_date ||= Date.today

    render layout: !request.xhr?
  end

  def copy
    source = CostObject.find(params[:id].to_i)
    if source
      @cost_object = create_cost_object(source.kind)
      @cost_object.copy_from(source)
    end

    # FIXME: I forcibly create a VariableCostObject for now. Following Ticket #5360
    @cost_object ||= VariableCostObject.new
    @cost_object.fixed_date ||= Date.today

    render action: :new, layout: !request.xhr?
  end

  def create
    if params[:cost_object]
      @cost_object = create_cost_object(params[:cost_object].delete(:kind))
    end

    # FIXME: I forcibly create a VariableCostObject for now. Following Ticket #5360
    @cost_object ||= VariableCostObject.new

    @cost_object.project_id = @project.id

    # fixed_date must be set before material_budget_items and labor_budget_items
    @cost_object.fixed_date = if params[:cost_object] && params[:cost_object][:fixed_date]
                                params[:cost_object].delete(:fixed_date)
                              else
                                Date.today
                              end

    @cost_object.attributes = permitted_params.cost_object
    @cost_object.attach_files(permitted_params.attachments.to_h)

    if @cost_object.save
      flash[:notice] = t(:notice_successful_create)
      redirect_to(params[:continue] ? { action: 'new' } :
                      { action: 'show', id: @cost_object })
    else
      render action: 'new', layout: !request.xhr?
    end
  end

  def edit
    # TODO: This method used to be responsible for both edit and update
    # Please remove code where necessary
    # check whether this method is needed at all
    @cost_object.attributes = permitted_params.cost_object if params[:cost_object]
  end

  def update
    # TODO: This was simply copied over from edit in order to have
    # something as a starting point for separating the two
    # Please go ahead and start removing code where necessary

    # TODO: use better way to prevent mass assignment errors
    params[:cost_object].delete(:kind)
    @cost_object.attributes = permitted_params.cost_object if params[:cost_object]
    if params[:cost_object][:existing_material_budget_item_attributes].nil?
      @cost_object.existing_material_budget_item_attributes = ({})
    end
    if params[:cost_object][:existing_labor_budget_item_attributes].nil?
      @cost_object.existing_labor_budget_item_attributes = ({})
    end

    @cost_object.attach_files(permitted_params.attachments.to_h)

    if @cost_object.save
      flash[:notice] = t(:notice_successful_update)
      redirect_to(params[:back_to] || { action: 'show', id: @cost_object })
    else
      render action: 'edit'
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = t(:notice_locking_conflict)
  end

  def destroy
    @cost_objects.each(&:destroy)
    flash[:notice] = t(:notice_successful_delete)
    redirect_to action: 'index', project_id: @project
  end

  def update_material_budget_item
    @element_id = params[:element_id]

    cost_type = CostType.where(id: params[:cost_type_id]).first

    if cost_type && params[:units].present?
      volume = Rate.parse_number_string_to_number(params[:units])
      @costs = (volume * cost_type.rate_at(params[:fixed_date]).rate rescue 0.0)
      @unit = volume == 1.0 ? cost_type.unit : cost_type.unit_plural
    else
      @costs = 0.0
      @unit = cost_type.try(:unit_plural) || ''
    end

    response = {
      "#{@element_id}_unit_name" => h(@unit),
      "#{@element_id}_currency" => Setting.plugin_openproject_costs['costs_currency']
    }
    if current_user.allowed_to?(:view_cost_rates, @project)
      response["#{@element_id}_costs"] = number_to_currency(@costs)
      response["#{@element_id}_cost_value"] = @costs
    end

    respond_to do |format|
      format.json do
        render json: response
      end
    end
  end

  def update_labor_budget_item
    @element_id = params[:element_id]
    user = User.where(id: params[:user_id]).first

    if user && params[:hours]
      hours = params[:hours].to_s.to_hours
      @costs = hours * user.rate_at(params[:fixed_date], @project).rate rescue 0.0
    else
      @costs = 0.0
    end

    response = {
      "#{@element_id}_unit_name" => h(@unit),
      "#{@element_id}_currency" => Setting.plugin_openproject_costs['costs_currency']
    }
    if current_user.allowed_to?(:view_hourly_rates, @project)
      response["#{@element_id}_costs"] = number_to_currency(@costs)
      response["#{@element_id}_cost_value"] = @costs
    end

    respond_to do |format|
      format.json do
        render json: response
      end
    end
  end

  private

  def create_cost_object(kind)
    case kind
    when FixedCostObject.name
      FixedCostObject.new
    when VariableCostObject.name
      VariableCostObject.new
    else
      CostObject.new
    end
  end

  def find_cost_object
    # This function comes directly from issues_controller.rb (Redmine 0.8.4)
    @cost_object = CostObject.includes(:project, :author).find_by(id: params[:id])
    @project = @cost_object.project if @cost_object
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_cost_objects
    # This function comes directly from issues_controller.rb (Redmine 0.8.4)

    @cost_objects = CostObject.where(id: params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @cost_objects.empty?
    projects = @cost_objects.map(&:project).compact.uniq
    if projects.size == 1
      @project = projects.first
    else
      # TODO: let users bulk edit/move/destroy cost_objects from different projects
      render_error 'Can not bulk edit/move/destroy cost objects from different projects' and return false
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
