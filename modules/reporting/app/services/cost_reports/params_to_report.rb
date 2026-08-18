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

module CostReports
  # Translates the reporting UI's request parameters into a CostReport.
  #
  # The parameters are the ones the reporting form posts: fields[], operators[],
  # values[], groups[rows][], groups[columns][] and unit.
  class ParamsToReport
    INACTIVE = "<<inactive>>"
    NULL = "<<null>>"

    def initialize(params, project: nil, user: User.current)
      @params = params
      @project = project
      @user = user
    end

    def call(report = new_report)
      report.query ||= report.build_default_query

      apply_filters(report)
      apply_axes(report)
      apply_unit(report)

      report
    end

    private

    attr_reader :params, :project, :user

    def new_report
      CostReport.new(project:, principal: user, name: I18n.t(:label_new_report))
    end

    def apply_filters(report)
      report.query.filters = []

      filter_params.each do |field, operator|
        values = Array(values_for(field))
        next if values == [INACTIVE]

        report.query.where(field.to_s, operator, values.map { |value| value == NULL ? nil : value })
      end
    end

    def apply_axes(report)
      report.apply_pivot_configuration(rows: axis(:rows), columns: axis(:columns))
    end

    def apply_unit(report)
      report.unit_id = params[:unit].to_i if params[:unit].present?
    end

    def filter_params
      return default_filters unless given_filters?

      Array(params[:fields]).compact_blank.index_with { |field| params[:operators][field] }
    end

    def values_for(field)
      return default_values[field.to_sym] unless given_filters?

      params[:values][field]
    end

    def axis(name)
      return default_axis(name) unless given_axes?

      Array(params[:groups][name.to_s])
    end

    def given_filters?
      params[:set_filter].to_i == 1
    end

    def given_axes?
      params[:set_filter].to_i == 1 && params[:groups].present?
    end

    def default_filters
      filters = { spent_on: ">d" }
      filters[:project_id] = "=" if project
      filters[:user_id] = "=" if user.logged?
      filters
    end

    def default_values
      {
        spent_on: [30.days.ago.strftime("%Y-%m-%d")],
        project_id: [project&.id.to_s],
        user_id: [::Queries::Filters::MeValue::KEY]
      }
    end

    def default_axis(name)
      case name
      when :columns then %w[week]
      else [project ? "work_package_id" : "project_id"]
      end
    end
  end
end
