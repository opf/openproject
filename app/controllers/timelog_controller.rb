#-- encoding: UTF-8

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

class TimelogController < ApplicationController
  helper_method :gon

  before_action :find_work_package, only: %i[new create]
  before_action :find_project, only: %i[new create]
  before_action :find_time_entry, only: %i[show edit update destroy]
  before_action :authorize, except: [:index]
  before_action :find_optional_project, only: [:index]

  include SortHelper
  include TimelogHelper
  include CustomFieldsHelper
  include PaginationHelper
  include Layout

  menu_item :time_entries

  def index
    # Set tab param to recognize correct selected tab
    params[:tab] = params[:tab] || 'details'

    sort_init 'spent_on', 'desc'
    sort_update 'spent_on' => 'spent_on',
                'user' => 'user_id',
                'activity' => 'activity_id',
                'project' => "#{Project.table_name}.name",
                'work_package' => 'work_package_id',
                'comments' => 'comments',
                'hours' => 'hours'

    cond = ARCondition.new
    if @issue
      cond << WorkPackage.self_and_descendants_of_condition(@issue)
    elsif @project
      cond << @project.project_condition(Setting.display_subprojects_work_packages?).to_sql
    end

    retrieve_date_range allow_nil: true
    if @from && @to
      cond << ['spent_on BETWEEN ? AND ?', @from, @to]
    end

    respond_to do |format|
      format.html do
        render layout: layout_non_or_no_menu
      end
      format.csv do
        # Export all entries
        @entries = TimeEntry
                   .visible
                   .includes(:project,
                             :activity,
                             :user,
                             work_package: %i[type assigned_to priority])
                   .references(:projects)
                   .where(cond.conditions)
                   .distinct(false)
                   .order(sort_clause)

        render csv: entries_to_csv(@entries), filename: 'timelog.csv'
      end
    end
  end

  def new
    @time_entry = new_time_entry(@project, @issue, permitted_params.time_entry.to_h)

    call_hook(:controller_timelog_edit_before_save, params: params, time_entry: @time_entry)

    render action: 'edit'
  end

  def create
    combined_params = permitted_params
                      .time_entry
                      .to_h
                      .reverse_merge(project: @project,
                                     work_package_id: @issue)

    call = TimeEntries::CreateService
           .new(user: current_user)
           .call(combined_params)

    @time_entry = call.result

    respond_for_saving call
  end

  def edit
    @time_entry.attributes = permitted_params.time_entry

    call_hook(:controller_timelog_edit_before_save, params: params, time_entry: @time_entry)
  end

  def update
    service = TimeEntries::UpdateService
              .new(user: current_user,
                   model: @time_entry)
    call = service.call(attributes: permitted_params.time_entry)
    respond_for_saving call
  end

  def destroy
    if @time_entry.destroy && @time_entry.destroyed?
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_delete)
          redirect_back fallback_location: { action: 'index', project_id: @time_entry.project }
        end
        format.json do
          render json: { text: l(:notice_successful_delete) }
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = l(:notice_unable_delete_time_entry)
          redirect_back fallback_location: { action: 'index', project_id: @time_entry.project }
        end
        format.json do
          render json: { isError: true, text: l(:notice_unable_delete_time_entry) }
        end
      end
    end
  end

  private

  def find_time_entry
    @time_entry = TimeEntry.find(params[:id])
    unless @time_entry.editable_by?(User.current)
      render_403
      return false
    end
    @project = @time_entry.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = Project.find(project_id_from_params) if @project.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def new_time_entry(project, work_package, attributes)
    time_entry = TimeEntry.new(project: project,
                               work_package: work_package,
                               user: User.current,
                               spent_on: User.current.today)

    time_entry.attributes = attributes

    time_entry
  end

  def respond_for_saving(call)
    @errors = call.errors

    if call.success?
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default action: 'index', project_id: @time_entry.project
        end
      end
    else
      respond_to do |format|
        format.html do
          render action: 'edit'
        end
      end
    end
  end

  def project_id_from_params
    if params.has_key?(:project_id)
      params[:project_id]
    elsif params.has_key?(:time_entry) && permitted_params.time_entry.has_key?(:project_id)
      permitted_params.time_entry[:project_id]
    end
  end

  def find_work_package
    @issue = work_package_from_params
    @project = @issue.project unless @issue.nil?
  end

  def work_package_from_params
    if params.has_key?(:work_package_id)
      work_package_id = params[:work_package_id]
    elsif params.has_key?(:time_entry) && permitted_params.time_entry.has_key?(:work_package_id)
      work_package_id = permitted_params.time_entry[:work_package_id]
    end

    WorkPackage.find_by id: work_package_id
  end

  def default_breadcrumb
    I18n.t(:label_spent_time)
  end
end
