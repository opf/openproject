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

class CostReportsController < ApplicationController
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
  before_action :load_and_authorize_in_optional_project
  before_action :find_optional_user

  include Layout

  helper_method :cost_types
  helper_method :cost_type
  helper_method :unit_id

  attr_accessor :report_engine, :cost_types, :unit_id, :cost_type

  helper_method :current_user
  helper_method :allowed_in_report?

  include ReportingHelper
  helper ReportingHelper
  helper { def engine; @report_engine; end }

  before_action :determine_engine
  before_action :prepare_query, only: %i[index create]
  before_action :find_optional_report, only: %i[index show update destroy rename]
  before_action :possibly_only_narrow_values

  before_action :set_cost_types # has to be set AFTER the Report::Controller filters run

  layout "angular/angular"

  # Checks if custom fields have been updated, added or removed since we
  # last saw them, to rebuild the filters and group bys.
  # Called once per request.
  def check_cache
    CostQuery::Cache.check
  end

  def index
    table

    unless performed?
      respond_to do |format|
        format.html do
          session[report_engine.name.underscore.to_sym].try(:delete, :name)
          render locals: { menu_name: project_or_global_menu }
        end

        format.xls do
          job_id = ::CostQuery::ScheduleExportService
            .new(user: current_user)
            .call(filter_params:, project: @project, cost_types: @cost_types)
            .result

          redirect_to job_status_path(job_id)
        end
      end
    end
  end

  ##
  # Render the report. Renders either the complete index or the table only
  def table
    if set_filter? && request.xhr?
      self.response_body = render_widget(Widget::Table, @query)
    end
  end

  current_menu_item [:index, :show] do |controller|
    controller.menu_item_to_highlight_on_index
  end

  def menu_item_to_highlight_on_index
    @project ? :costs : :cost_reports_global
  end

  ##
  # Create a new saved query. Returns the redirect url to an XHR or redirects directly
  def create
    @query.name = params[:query_name].presence || ::I18n.t(:label_default)
    @query.public! if make_query_public?
    @query.send(:"#{user_key}=", current_user.id)
    @query.save!

    redirect_params = { action: "show", id: @query.id }
    redirect_params[:project_id] = @project.identifier if @project

    if request.xhr? # Update via AJAX - return url for redirect
      render plain: url_for(**redirect_params)
    else # Redirect to the new record
      redirect_to **redirect_params
    end
  end

  ##
  # Show a saved record, if found. Raises RecordNotFound if the specified query
  # at :id does not exist
  def show
    if @query
      store_query(@query)
      table
      render action: "index", locals: { menu_name: project_or_global_menu } unless performed?
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  ##
  # Delete a saved record, if found. Redirects to index on success, raises a
  # RecordNotFound if the query at :id does not exist
  def destroy
    if @query
      @query.destroy if allowed_in_report?(:destroy, @query)
    else
      raise ActiveRecord::RecordNotFound
    end
    redirect_to action: "index", default: 1, id: nil
  end

  ##
  # Update a record with new query parameters and save it. Redirects to the
  # specified record or renders the updated table on XHR
  def update
    if params[:set_filter].to_i == 1 # save
      old_query = @query
      prepare_query
      old_query.migrate(@query)
      old_query.save!
      @query = old_query
    end
    if request.xhr?
      table
    else
      redirect_to action: "show", id: @query.id
    end
  end

  ##
  # Rename a record and update its publicity. Redirects to the updated record or
  # renders the updated name on XHR
  def rename
    @query.name = params[:query_name]
    @query.public! if make_query_public?
    @query.save!
    store_query(@query)
    if request.xhr?
      render plain: @query.name
    else
      redirect_to action: "show", id: @query.id
    end
  end

  def drill_down
    redirect_to action: :index
  end

  # renders option tags for each available value for a single filter
  def available_values
    name = params[:filter_name]

    return unless name

    f_cls = get_filter_class(name)
    filter = f_cls.new.tap do |f|
      f.values = JSON.parse(params[:values].tr("'", '"')) if params[:values].present? && params[:values]
    end
    render_widget Widget::Filters::Option, filter, to: canvas = ""

    render plain: canvas, layout: !request.xhr?
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
      operators: { spent_on: ">d" },
      values: { spent_on: [30.days.ago.strftime("%Y-%m-%d")] }
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
    filters = http_filter_parameters if set_filter?
    filters ||= session[report_engine.name.underscore.to_sym].try(:[], :filters)
    filters ||= default_filter_parameters

    update_project_context!(filters)

    filters
  end

  ##
  # Return the active group bys
  def group_params
    groups = http_group_parameters if set_filter?
    groups ||= session[report_engine.name.underscore.to_sym].try(:[], :groups)
    groups || default_group_parameters
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
    filters[:operators].merge! project_id: "="
    filters[:values].merge! project_id: [project_id]
  end

  def set_me_filter(filters)
    filters[:operators].merge! user_id: "="
    filters[:values].merge! user_id: [CostQuery::Filter::UserId.me_value]
  end

  ##
  # Set a default query to cut down initial load time
  def default_group_parameters
    { columns: [:week], rows: [] }.tap do |h|
      h[:rows] << if @project
                    :work_package_id
                  else
                    :project_id
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
                 cost_type_filter = @query.filters.detect { |f| f.is_a?(CostQuery::Filter::CostTypeId) }

                 cost_type_filter.values.first.to_i if cost_type_filter
               end

    @unit_id = -1 unless @cost_types.include? @unit_id
  end

  # Determine the active cost type, if it is not labor or money, and add a hidden filter to the query
  #   sets the @cost_type -> this is used to select the proper units for display
  def set_cost_type
    return unless @query

    @query.filter :cost_type_id, operator: "=", value: @unit_id.to_s, display: false
    @cost_type = CostType.find(@unit_id) if @unit_id > 0
  end

  #   set the @cost_types -> this is used to determine which tabs to display
  def set_active_cost_types
    unless session[:report] && (@cost_types = session[:report][:filters][:values][:cost_type_id].try(:collect, &:to_i))
      relevant_cost_types = CostType.select(:id).order(Arel.sql("id ASC")).select do |t|
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
  def allowed_in_report?(action, report, user = User.current) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    # admins may do everything
    return true if user.admin?

    # If this report does belong to a project but not to the current project, we
    # should not do anything with it. It fact, this should never happen.
    return false if report.project.present? && report.project != @project

    permissions =
      case action
      when :create
        %i[save_cost_reports save_private_cost_reports]
      when :save, :destroy, :rename
        if report.is_public?
          %i[save_cost_reports]
        else
          %i[save_cost_reports save_private_cost_reports]
        end
      when :save_as_public
        %i[save_cost_reports]
      end

    # If report does not belong to a project, it is ok to look for the
    # permission in any project. Otherwise, the user should have the permission
    # in this project.

    if report.project
      Array(permissions).any? { |permission| user.allowed_in_project?(permission, @project) }
    else
      Array(permissions).any? { |permission| user.allowed_in_any_project?(permission) }
    end
  end

  private

  def find_optional_user
    @current_user = User.current || User.anonymous
  end

  def get_filter_class(name)
    filter = report_engine::Filter
      .all
      .detect { |cls| cls.to_s.demodulize.underscore == name.to_s }

    raise ArgumentError.new("Filter with name #{name} does not exist.") unless filter

    filter
  end

  ##
  # Determine the available values for the specified filter and return them as
  # json, if that was requested. This will be executed INSTEAD of the actual action
  def possibly_only_narrow_values
    if params[:narrow_values] == "1"
      sources = params[:sources]
      dependent = params[:dependent]

      query = report_engine.new
      sources.each do |dependency|
        query.filter(dependency.to_sym,
                     operator: params[:operators][dependency],
                     values: params[:values][dependency])
      end
      query.column(dependent)
      values = [[::I18n.t(:label_inactive), "<<inactive>>"]] + query.result.map { |r| r.fields[query.group_bys.first.field] }
      # replace null-values with corresponding placeholder
      values = values.map { |value| value.nil? ? [::I18n.t(:label_none), "<<null>>"] : value }
      # try to find corresponding labels to the given values
      values = values.map do |value|
        filter = get_filter_class(dependent)
        filter_value = filter.label_for_value value
        if filter_value && filter_value.first.is_a?(Symbol)
          [::I18n.t(filter_value.first), filter_value.second]
        elsif filter_value && filter_value.first.is_a?(String)
          [filter_value.first, filter_value.second]
        else
          value
        end
      end
      render json: values.to_json
    end
  end

  ##
  # Determines if the request contains filters to set
  # FIXME: rename to set_query?
  def set_filter?
    params[:set_filter].to_i == 1
  end

  ##
  # Extract active filters from the http params
  def http_filter_parameters
    params[:fields] ||= []
    (params[:fields].reject(&:empty?) || []).inject(operators: {}, values: {}) do |hash, field|
      hash[:operators][field.to_sym] = params[:operators][field]
      hash[:values][field.to_sym] = params[:values][field]
      hash
    end
  end

  ##
  # Extract active group bys from the http params
  def http_group_parameters
    if params[:groups]
      rows = params[:groups]["rows"]
      columns = params[:groups]["columns"]
    end
    { rows: rows || [], columns: columns || [] }
  end

  ##
  # Determines if the query settings should be reset
  def force_default?
    params[:default].to_i == 1
  end

  ##
  # Prepare the query from the request
  def prepare_query
    determine_settings
    @query = build_query(session[report_engine.name.underscore.to_sym][:filters],
                         session[report_engine.name.underscore.to_sym][:groups])

    set_cost_type if @unit_id.present?
  end

  ##
  # Determine the query settings the current request and save it to
  # the session.
  def determine_settings
    if force_default?
      filters = default_filter_parameters
      groups  = default_group_parameters
      session[report_engine.name.underscore.to_sym].try :delete, :name
    else
      filters = filter_params
      groups  = group_params
    end
    cookie = session[report_engine.name.underscore.to_sym] || {}
    session[report_engine.name.underscore.to_sym] = cookie.merge(filters:, groups:)
  end

  ##
  # Build the query from the passed session hash
  def build_query(filters, groups = {})
    query = report_engine.new project: @project
    query.tap do |q|
      filters[:operators].each do |filter, operator|
        unless filters[:values][filter] == ["<<inactive>>"]
          values = Array(filters[:values][filter]).map { |v| v == "<<null>>" ? nil : v }
          q.filter(filter.to_sym,
                   operator:,
                   values:)
        end
      end
    end
    groups[:columns].try(:reverse_each) { |c| query.column(c) }
    groups[:rows].try(:reverse_each) { |r| query.row(r) }
    query
  end

  ##
  # Store query in the session
  def store_query(_query)
    cookie = {}
    cookie[:groups] = @query.group_bys.inject({}) do |h, group|
      ((h[:"#{group.type}s"] ||= []) << group.underscore_name.to_sym) && h
    end
    cookie[:filters] = @query.filters.inject(operators: {}, values: {}) do |h, filter|
      h[:operators][filter.underscore_name.to_sym] = filter.operator.to_s
      h[:values][filter.underscore_name.to_sym] = filter.values
      h
    end
    cookie[:name] = @query.name if @query.name
    session[report_engine.name.underscore.to_sym] = cookie
  end

  ##
  # Override in subclass if user key
  def user_key
    "user_id"
  end

  ##
  # Override in subclass if you like
  def is_public_sql(val = true)
    "(is_public = #{val ? report_engine.reporting_connection.quoted_true : report_engine.reporting_connection.quoted_false})"
  end

  def make_query_public?
    !!params[:query_is_public]
  end

  ##
  # Find a report if :id was passed as parameter.
  # Raises RecordNotFound if an invalid :id was passed.
  #
  # @param query An optional query added to the disjunction qualifiying reports to be returned.
  def find_optional_report(query = "1=0")
    if params[:id]
      @query = report_engine
                 .where(["#{is_public_sql} OR (#{user_key} = ?) OR (#{query})", current_user.id])
                 .find(params[:id].to_i)
      @query.deserialize if @query
    end
  rescue ActiveRecord::RecordNotFound
  end
end
