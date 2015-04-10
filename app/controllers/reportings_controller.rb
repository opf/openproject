#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class ReportingsController < ApplicationController
  unloadable
  helper :timelines

  before_filter :disable_api
  before_filter :find_project_by_project_id
  before_filter :authorize

  before_filter :find_reporting, only: [:show, :edit, :update, :confirm_destroy, :destroy]
  before_filter :build_reporting, only: :create

  before_filter :check_visibility, except: [:create, :index, :new, :available_projects]

  accept_key_auth :index, :show

  menu_item :reportings

  def available_projects
    available_projects = @project.reporting_to_project_candidates
    respond_to do |format|
      format.html { render_404 }
    end
  end

  def index
    condition_params = []
    temp_condition = ''
    condition = ''

    if params[:project_types].present?
      project_types = params[:project_types].split(/,/).map(&:to_i)
      temp_condition += "#{Project.quoted_table_name}.project_type_id IN (?)"
      condition_params << project_types
      if project_types.include?(-1)
        temp_condition += " OR #{Project.quoted_table_name}.project_type_id IS NULL"
        temp_condition = "(#{temp_condition})"
      end
    end

    condition += temp_condition
    temp_condition = ''

    if params[:project_statuses].present?
      condition += ' AND ' unless condition.empty?

      project_statuses = params[:project_statuses].split(/,/).map(&:to_i)
      temp_condition += "#{Reporting.quoted_table_name}.reported_project_status_id IN (?)"
      condition_params << project_statuses
      if project_statuses.include?(-1)
        temp_condition += " OR #{Reporting.quoted_table_name}.reported_project_status_id IS NULL"
        temp_condition = "(#{temp_condition})"
      end
    end

    condition += temp_condition
    temp_condition = ''

    if params[:project_responsibles].present?
      condition += ' AND ' unless condition.empty?

      project_responsibles = params[:project_responsibles].split(/,/).map(&:to_i)
      temp_condition += "#{Project.quoted_table_name}.responsible_id IN (?)"
      condition_params << project_responsibles
      if project_responsibles.include?(-1)
        temp_condition += " OR #{Project.quoted_table_name}.responsible_id  IS NULL"
        temp_condition = "(#{temp_condition})"
      end
    end

    condition += temp_condition
    temp_condition = ''

    if params[:project_parents].present?
      condition += ' AND ' unless condition.empty?

      project_parents = params[:project_parents].split(/,/).map(&:to_i)
      nested_set_selection = Project.find(project_parents).map { |p| p.lft..p.rgt }.inject([]) { |r, e| e.each { |i| r << i }; r }

      temp_condition += "#{Project.quoted_table_name}.lft IN (?)"
      condition_params << nested_set_selection
    end

    condition += temp_condition
    temp_condition = ''

    if params[:grouping_one].present? && condition.present?
      condition += ' OR '

      grouping = params[:grouping_one].split(/,/).map(&:to_i)
      temp_condition += "#{Project.quoted_table_name}.id IN (?)"
      condition_params << grouping
    end

    condition += temp_condition
    conditions = [condition] + condition_params unless condition.empty?

    case params[:only]
    when 'via_source'
      @reportings = @project.reportings_via_source.find(:all,
                                                        include: :project,
                                                        conditions: conditions
        )
    when 'via_target'
      @reportings = @project.reportings_via_target.find(:all,
                                                        include: :project,
                                                        conditions: conditions
        )
    else
      @reportings = @project.reportings.all
    end

    # get all reportings for which projects have ancestors.
    nested_sets_for_parents = (@reportings.inject([]) { |r, e| r << e.reporting_to_project; r << e.project }).uniq.map { |p| [p.lft, p.rgt] }

    condition_params = []
    temp_condition = ''
    condition = ''

    nested_sets_for_parents.each do |set|
      condition += ' OR ' unless condition.empty?
      condition += "#{Project.quoted_table_name}.lft < ? AND #{Project.quoted_table_name}.rgt > ?"
      condition_params << set[0]
      condition_params << set[1]
    end

    conditions = [condition] + condition_params unless condition.empty?

    case params[:only]
    when 'via_source'
      @ancestor_reportings = @project.reportings_via_source.find(:all,
                                                                 include: :project,
                                                                 conditions: conditions
        )
    when 'via_target'
      @ancestor_reportings = @project.reportings_via_target.find(:all,
                                                                 include: :project,
                                                                 conditions: conditions
        )
    else
      @ancestor_reportings = @project.reportings.all
    end

    @reportings = (@reportings + @ancestor_reportings).uniq

    respond_to do |format|
      format.html do
        @reportings = @project.reportings_via_source.all.select(&:visible?)
      end
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def new
    @reporting_to_project_candidates = @project.reporting_to_project_candidates
    if @reporting_to_project_candidates.blank?
      flash[:warning] = l('timelines.no_projects_for_reporting_available')
      redirect_to project_reportings_path(@project)
    else
      @reporting = Reporting.new

      respond_to do |format|
        format.html
      end
    end
  end

  def create
    if @reporting.reporting_to_project.present? && @reporting.project.visible? && @reporting.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_reportings_path
    else
      flash.now[:error] = l('timelines.reporting_could_not_be_saved')
      render action: 'new'
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @reporting.update_attributes(params[:reporting])
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_reportings_path
    else
      flash.now[:error] = l('timelines.reporting_could_not_be_saved')
      render action: :edit
    end
  end

  def confirm_destroy
    respond_to do |format|
      format.html
    end
  end

  def destroy
    @reporting.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to project_reportings_path
  end

  protected

  def find_reporting
    @reporting = @project.reportings_via_source.find(params[:id])
  end

  def build_reporting
    @reporting = @project.reportings_via_source.build
    @reporting.reporting_to_project_id = params['reporting']['reporting_to_project_id']
  end

  def check_visibility
    raise ActiveRecord::RecordNotFound unless @reporting.visible?
  end

  def default_breadcrumb
    l('timelines.project_menu.reportings')
  end
end
