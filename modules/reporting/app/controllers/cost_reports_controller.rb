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

class CostReportsController < ApplicationController
  module QueryPreperation
    ##
    # Make sure to add cost type filter after the
    # query filters have been reset by .prepare_query
    # from the Report::Controller.
    def prepare_query
      query = super

      set_cost_type if @unit_id.present?

      query
    end
  end

  rescue_from Exception do |exception|
    session.delete(CostQuery.name.underscore.to_sym)
    raise exception
  end

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    render_404
  end

  Widget::Base.dont_cache!

  before_action :check_cache
  before_action :load_all
  before_action :find_optional_project
  before_action :find_optional_user

  include Report::Controller
  include Layout
  prepend QueryPreperation

  before_action :set_cost_types # has to be set AFTER the Report::Controller filters run

  helper_method :cost_types
  helper_method :cost_type
  helper_method :unit_id
  helper_method :public_queries
  helper_method :private_queries

  attr_accessor :cost_types, :unit_id, :cost_type

  # Checks if custom fields have been updated, added or removed since we
  # last saw them, to rebuild the filters and group bys.
  # Called once per request.
  def check_cache
    CostQuery::Cache.check
  end

  ##
  # @Override
  # Use respond_to hook, so redmine_export can hook up the excel exporting
  def index
    super
    respond_to do |format|
      format.html {
        session[report_engine.name.underscore.to_sym].try(:delete, :name)
        render action: 'index', layout: layout_non_or_no_menu
      }
    end unless performed?
  end

  current_menu_item :index do |controller|
    controller.menu_item_to_highlight_on_index
  end

  def menu_item_to_highlight_on_index
    @project ? :cost_reports : :cost_reports_global
  end

  def drill_down
    redirect_to action: :index
  end

  ##
  # Determines if the request sets a unit type
  def set_unit?
    params[:unit]
  end

  ##
  # @Override
  # We cannot show a progressbar in Redmine, due to Prototype being less than 1.7
  def no_progress?
    true
  end

  ##
  # Set a default query to cut down initial load time
  def default_filter_parameters
    {
      operators: { spent_on: '>d' },
      values: { spent_on: [30.days.ago.strftime('%Y-%m-%d')] }
    }.tap do |hash|
      if @project
        set_project_filter(hash, @project.id)
      end

      if current_user.logged?
        set_me_filter(hash)
      end
    end
  end

  ##
  # Get the filter params with an optional project context
  def filter_params
    filters = super
    update_project_context!(filters)

    filters
  end

  ##
  # Clear the query if the project context changed
  def update_project_context!(filters)

    # Only in project context
    return unless @project

    # Only if the project context changed
    context = filters[:project_context]

    # Context is same, don't set project (allow override)
    return if context == @project.id

    # Reset context if project missing
    if context.nil?
      filters[:project_context] = @project.id
      return
    end

    # Update the project context and project_id filter
    set_project_filter(filters, @project.id)
  end

  def set_project_filter(filters, project_id)
    filters[:project_context] = project_id
    filters[:operators].merge! project_id: '='
    filters[:values].merge! project_id: [project_id]
  end

  def set_me_filter(filters)
    filters[:operators].merge! user_id: '='
    filters[:values].merge! user_id: [CostQuery::Filter::UserId.me_value]
  end

  ##
  # Set a default query to cut down initial load time
  def default_group_parameters
    { columns: [:week], rows: [] }.tap do |h|
      if @project
        h[:rows] << :work_package_id
      else
        h[:rows] << :project_id
      end
    end
  end

  ##
  # Determine active cost types, the currently selected unit and corresponding cost type
  def set_cost_types
    set_active_cost_types
    set_unit
    set_cost_type
  end

  # Determine the currently active unit from the parameters or session
  #   sets the @unit_id -> this is used in the index for determining the active unit tab
  def set_unit
    @unit_id = if set_unit?
                 params[:unit].to_i
               elsif @query.present?
                 cost_type_filter =  @query.filters.detect { |f| f.is_a?(CostQuery::Filter::CostTypeId) }

                 cost_type_filter.values.first.to_i if cost_type_filter
    end

    @unit_id = -1 unless @cost_types.include? @unit_id
  end

  # Determine the active cost type, if it is not labor or money, and add a hidden filter to the query
  #   sets the @cost_type -> this is used to select the proper units for display
  def set_cost_type
    return unless @query

    @query.filter :cost_type_id, operator: '=', value: @unit_id.to_s, display: false
    @cost_type = CostType.find(@unit_id) if @unit_id > 0
  end

  #   set the @cost_types -> this is used to determine which tabs to display
  def set_active_cost_types
    unless session[:report] && (@cost_types = session[:report][:filters][:values][:cost_type_id].try(:collect, &:to_i))
      relevant_cost_types = CostType.select(:id).order(Arel.sql('id ASC')).select do |t|
        t.cost_entries.count > 0
      end.collect(&:id)
      @cost_types = [-1, 0, *relevant_cost_types]
    end
  end

  def load_all
    CostQuery::GroupBy.all
    CostQuery::Filter.all
  end

  # @Override
  def determine_engine
    @report_engine = CostQuery
    @title = "label_#{@report_engine.name.underscore}"
  end

  # N.B.: Users with save_cost_reports permission implicitly have
  # save_private_cost_reports permission as well
  #
  # @Override
  def allowed_to?(action, report, user = User.current)
    # admins may do everything
    return true if user.admin?

    # If this report does belong to a project but not to the current project, we
    # should not do anything with it. It fact, this should never happen.
    return false if report.project.present? && report.project != @project

    # If report does not belong to a project, it is ok to look for the
    # permission in any project. Otherwise, the user should have the permission
    # in this project.
    if report.project.present?
      options = {}
    else
      options = { global: true }
    end

    case action
    when :create
      user.allowed_to?(:save_cost_reports, @project, options) or
        user.allowed_to?(:save_private_cost_reports, @project, options)

    when :save, :destroy, :rename
      if report.is_public?
        user.allowed_to?(:save_cost_reports, @project, options)
      else
        user.allowed_to?(:save_cost_reports, @project, options) or
          user.allowed_to?(:save_private_cost_reports, @project, options)
      end

    when :save_as_public
      user.allowed_to?(:save_cost_reports, @project, options)

    else
      false
    end
  end

  def public_queries
    if @project
      CostQuery.where(['is_public = ? AND (project_id IS NULL OR project_id = ?)', true, @project])
               .order(Arel.sql('name ASC'))
    else
      CostQuery.where(['is_public = ? AND project_id IS NULL', true])
               .order(Arel.sql('name ASC'))
    end
  end

  def private_queries
    if @project
      CostQuery.where(['user_id = ? AND is_public = ? AND (project_id IS NULL OR project_id = ?)',
                       current_user,
                       false,
                       @project])
               .order(Arel.sql('name ASC'))
    else
      CostQuery.where(['user_id = ? AND is_public = ? AND project_id IS NULL', current_user, false])
               .order(Arel.sql('name ASC'))
    end
  end

  def display_report_list
    report_type = params[:report_type] || :public
    render partial: 'report_list', locals: { report_type: report_type }, layout: !request.xhr?
  end

  private

  def find_optional_user
    @current_user = User.current || User.anonymous
  end
end
