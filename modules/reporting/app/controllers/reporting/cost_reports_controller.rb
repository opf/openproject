# frozen_string_literal: true

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Reporting
  class CostReportsController < ApplicationController
    include Layout
    include ReportingHelper

    helper ReportingHelper
    helper { def engine = ::CostQuery }

    # Widgets render into a shared canvas but cache the whole canvas under their
    # own key, so a cached widget replays everything rendered before it.
    Widget::Base.dont_cache!

    before_action :check_cache
    before_action :load_all
    before_action :load_and_authorize_in_optional_project
    before_action :find_report, only: %i[show update rename destroy]
    before_action :build_report, only: %i[index create]
    before_action :narrow_values_only, only: %i[index]
    before_action :set_cost_types

    helper_method :cost_types, :cost_type, :unit_id, :allowed_in_report?

    current_menu_item(%i[index show], &:menu_item_to_highlight_on_index)

    def menu_item_to_highlight_on_index
      @project ? :costs : :cost_reports_global
    end

    def index
      respond_to do |format|
        format.html { render_report }
        format.xls { export(:xls) }
        format.pdf { export(:pdf) }
      end
    end

    def show
      render_report
    end

    def create
      return deny_access if make_public? && !allowed_in_report?(:save_as_public, @report)

      @report.name = params[:query_name].presence || I18n.t(:label_default)
      @report.public = make_public?
      @report.save!

      redirect_to_report
    end

    def update
      return deny_access unless allowed_in_report?(:save, @report)

      ::CostReports::ParamsToReport.new(params, project: @project, user: current_user).call(@report)
      @report.save!

      if request.xhr?
        render_table
      else
        redirect_to_report
      end
    end

    def rename
      return deny_access unless allowed_in_report?(:rename, @report)

      @report.name = params[:query_name]
      @report.public = make_public? if make_public?
      @report.save!

      if request.xhr?
        render plain: @report.name
      else
        redirect_to_report
      end
    end

    def destroy
      return deny_access unless allowed_in_report?(:destroy, @report)

      @report.destroy!

      redirect_to reports_path, status: :see_other
    end

    # Renders the option tags for the available values of a single filter.
    def available_values
      return head :bad_request if params[:filter_name].blank?

      canvas = +"".html_safe
      render_widget Widget::Filters::Option, requested_filter, to: canvas

      render html: canvas, layout: !request.xhr?
    end

    private

    def requested_filter
      filter_class(params[:filter_name]).new.tap do |filter|
        filter.values = requested_filter_values if params[:values].present?
      end
    end

    def requested_filter_values
      JSON.parse(params.expect(:values).tr("'", '"'))
    end

    def find_report
      @report = CostReport.visible(current_user).find(params.expect(:id))

      if params[:set_filter].to_i == 1
        ::CostReports::ParamsToReport.new(params, project: @project, user: current_user).call(@report)
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def build_report
      @report = ::CostReports::ParamsToReport.new(params, project: @project, user: current_user).call
    end

    def render_report
      return render_table if request.xhr?

      render "reporting/cost_reports/index", locals: { menu_name: project_or_global_menu }
    end

    def render_table
      self.response_body = render_widget(Widget::Table, @report)
    end

    def export(format)
      job_id = ::CostQuery::ScheduleExportService
                 .new(user: current_user)
                 .call(format:,
                       query_id: @report.id,
                       query_name: @report.name,
                       filter_params: export_filter_params,
                       project: @project,
                       cost_types: @cost_types)
                 .result

      if request.headers["Accept"]&.include?("application/json")
        render json: { job_id: }
      else
        redirect_to job_status_path(job_id)
      end
    end

    # The export jobs still rebuild the report through the reporting engine, which
    # takes the filters in the shape the reporting form posts them.
    def export_filter_params
      @report.query.filters.each_with_object({ operators: {}, values: {} }) do |filter, params|
        params[:operators][filter.name] = filter.operator
        params[:values][filter.name] = filter.values
      end
    end

    def redirect_to_report
      path = if @project
               project_reporting_cost_report_path(@project, @report)
             else
               reporting_cost_report_path(@report)
             end

      if request.xhr?
        render plain: path
      else
        redirect_to path
      end
    end

    def reports_path
      @project ? project_reporting_cost_reports_path(@project) : global_reporting_cost_reports_path
    end

    def check_cache
      ::CostQuery::Cache.check
    end

    def load_all
      ::CostQuery::GroupBy.all
      ::CostQuery::Filter.all
    end

    def filter_class(name)
      ::CostQuery::Filter.all.detect { |filter| filter.underscore_name == name }
    end

    def make_public?
      params[:query_is_public].present?
    end

    def set_cost_types
      @cost_types = available_cost_types
      @unit_id = selected_unit_id
      @cost_type = CostType.find(@unit_id) if @unit_id > 0
      @report.unit_id = @unit_id
    end

    def available_cost_types
      relevant = CostType.select(:id).order(Arel.sql("id ASC")).select { |type| type.cost_entries.exists? }

      [-1, 0, *relevant.map(&:id)]
    end

    def selected_unit_id
      candidate = params[:unit].presence&.to_i || @report.unit_id

      @cost_types.include?(candidate) ? candidate : -1
    end

    # Users with save_cost_reports implicitly have save_private_cost_reports too.
    def allowed_in_report?(action, report, user = User.current)
      return true if user.admin?
      return false if report.project.present? && report.project != @project

      permissions = permissions_for(action, report)

      if report.project
        permissions.any? { |permission| user.allowed_in_project?(permission, @project) }
      else
        permissions.any? { |permission| user.allowed_in_any_project?(permission) }
      end
    end

    def permissions_for(action, report)
      case action
      when :create then %i[save_cost_reports save_private_cost_reports]
      when :save, :destroy, :rename
        report.public? ? %i[save_cost_reports] : %i[save_cost_reports save_private_cost_reports]
      when :save_as_public then %i[save_cost_reports]
      else []
      end
    end

    # Answers the dependent filter's available values as json instead of running
    # the action, which is what the filter UI asks for while narrowing a value.
    def narrow_values_only
      return unless params[:narrow_values] == "1"

      render json: ::CostReports::NarrowedValues.new(params).call.to_json
    end
  end
end
