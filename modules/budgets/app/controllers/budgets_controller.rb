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

class BudgetsController < ApplicationController
  include AttachableServiceCall

  before_action :find_budget, only: %i[show edit update copy destroy_info destroy]
  before_action :find_project_by_project_id, only: %i[new create update_material_budget_item update_labor_budget_item]
  before_action :find_optional_project, only: :index
  before_action :check_if_workpackages_need_reassignment, only: :destroy

  before_action :authorize_global, only: :index
  before_action :authorize, except: [
    :index,
    # unrestricted actions
    :update_material_budget_item,
    :update_labor_budget_item
  ]

  no_authorization_required! :update_material_budget_item,
                             :update_labor_budget_item

  helper :sort
  include SortHelper

  helper :projects
  include ProjectsHelper

  helper :attachments
  include AttachmentsHelper

  helper :costlog
  include CostlogHelper

  helper :budgets
  include BudgetsHelper
  include PaginationHelper
  include ::Costs::NumberHelper

  def index
    sort_init "id", "desc"
    sort_update default_budget_sort

    @budgets = visible_sorted_budgets

    respond_to do |format|
      format.html do
        render action: "index", layout: !request.xhr?
      end
      format.csv { send_data(budgets_to_csv(@budgets), type: "text/csv; header=present", filename: "export.csv") }
    end
  end

  def show
    @edit_allowed = User.current.allowed_in_project?(:edit_budgets, @project)

    respond_to do |format|
      format.html { render action: "show", layout: !request.xhr? }
    end
  end

  def new
    @budget ||= Budget.new
    @budget.project_id = @project.id
    @budget.fixed_date ||= Date.today

    render layout: !request.xhr?
  end

  def copy
    source = Budget.find(params[:id].to_i)

    @budget =
      if source
        Budget.new_copy(source)
      else
        Budget.new
      end

    @budget.fixed_date ||= Date.today

    render action: :new, layout: !request.xhr?
  end

  def edit
    @budget.attributes = permitted_params.budget if params[:budget]
  end

  def create
    call = attachable_create_call ::Budgets::CreateService,
                                  args: permitted_params.budget.merge(project: @project)
    @budget = call.result

    if call.success?
      flash[:notice] = t(:notice_successful_create)
      redirect_to(params[:continue] ? { action: "new" } : { action: "show", id: @budget })
    else
      render action: "new", status: :unprocessable_entity, layout: !request.xhr?
    end
  end

  def update
    call = attachable_update_call ::Budgets::UpdateService,
                                  model: @budget,
                                  args: permitted_params.budget

    if call.success?
      flash[:notice] = t(:notice_successful_update)
      redirect_to(@budget)
    else
      @budget = call.result
      render action: :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = t(:notice_locking_conflict)
  end

  def destroy
    reassign_or_nullify_work_package_budgets

    @budget.destroy!

    flash[:notice] = t(:notice_successful_delete)
    redirect_to action: "index", project_id: @project, status: :see_other
  end

  def destroy_info
    @possible_other_budgets = @project.budgets.where.not(id: @budget.id)
  end

  def update_material_budget_item # rubocop:disable Metrics/AbcSize
    @element_id = params[:element_id]

    cost_type = CostType.where(id: params[:cost_type_id]).first

    if cost_type && params[:units].present?
      volume = Rate.parse_number_string_to_number(params[:units])
      @costs = begin
        volume * cost_type.rate_at(params[:fixed_date]).rate
      rescue StandardError
        0.0
      end
      @unit = volume == 1.0 ? cost_type.unit : cost_type.unit_plural
    else
      @costs = 0.0
      @unit = cost_type.try(:unit_plural) || ""
    end

    respond_to do |format|
      format.json do
        render json: render_item_as_json(@element_id, @costs, @unit, @project, :view_cost_rates)
      end
    end
  end

  def update_labor_budget_item # rubocop:disable Metrics/AbcSize
    @element_id = params[:element_id]
    user = User.visible.in_project(@project).find_by(id: params[:user_id])

    if user && params[:hours]
      hours = Rate.parse_number_string_to_number(params[:hours])
      @costs = begin
        hours * user.rate_at(params[:fixed_date], @project).rate
      rescue StandardError
        0.0
      end
    else
      @costs = 0.0
    end

    respond_to do |format|
      format.json do
        render json: render_item_as_json(@element_id, @costs, @unit, @project, :view_hourly_rates)
      end
    end
  end

  private

  def find_budget
    @budget = Budget.visible.includes(:project, :author).find(params[:id])
    @project = @budget.project if @budget
  end

  def render_item_as_json(element_id, costs, unit, project, permission)
    response = {
      "#{element_id}_unit_name" => ActionController::Base.helpers.sanitize(unit),
      "#{element_id}_currency" => Setting.costs_currency
    }

    if current_user.allowed_in_project?(permission, project)
      response["#{element_id}_costs"] = number_to_currency(costs)
      response["#{element_id}_cost_value"] = response["#{element_id}_amount"] = unitless_currency_number(costs)
    end

    response
  end

  def default_budget_sort
    {
      "id" => "#{Budget.table_name}.id",
      "subject" => "#{Budget.table_name}.subject",
      "fixed_date" => "#{Budget.table_name}.fixed_date"
    }
  end

  def visible_sorted_budgets
    Budget
      .visible(current_user)
      .order(sort_clause)
      .includes(:author)
      .where(project_id: @project.id)
      .page(page_param)
      .per_page(per_page_param)
  end

  def check_if_workpackages_need_reassignment
    if @budget.work_packages.any? && params[:todo].blank?
      redirect_to destroy_info_budget_path(@budget), status: :see_other
    end
  end

  def reassign_or_nullify_work_package_budgets # rubocop:disable Metrics/AbcSize
    return unless params[:todo].in?(%w[reassign delete])

    reassign_to_id = if params[:todo] == "reassign"
                       # Only allow reassignment to budgets that are visible to the user and belong to the same project
                       # If budget is not visible this will raise and we will return a 404
                       @project.budgets.visible.find(params[:reassign_to_id]).id
                     elsif params[:todo] == "delete"
                       nil
                     end

    @budget.work_packages.find_each(batch_size: 100) do |work_package|
      work_package.journal_cause = Journal::CausedByBudgetDeletion.new(budget: @budget)
      work_package.update!(budget_id: reassign_to_id)
    end
  end
end
