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
  # Answers the values still available for a filter, given the filters it depends
  # on. The filter UI asks for this while the user narrows a selection.
  class NarrowedValues
    def initialize(params)
      @params = params
    end

    def call
      values = [[I18n.t(:label_inactive), ParamsToReport::INACTIVE]] + dependent_values

      values.map { |value| label_for(value) }
    end

    private

    attr_reader :params

    def dependent_values
      field = chain.group_bys.first.field

      chain.result.map { |result| result.fields[field] }
    end

    def chain
      @chain ||= CostReport.new(query: CostReportQuery.new).tap do |report|
        apply_sources(report)

        report.apply_pivot_configuration(rows: [], columns: [params[:dependent]])
      end
    end

    def apply_sources(report)
      Array(params[:sources]).each do |source|
        report.query.where(source, params[:operators][source], Array(params[:values][source]))
      end
    end

    def label_for(value)
      return [I18n.t(:label_none), ParamsToReport::NULL] if value.nil?

      label = filter_class.label_for_value(value)
      return value if label.blank?

      label.first.is_a?(Symbol) ? [I18n.t(label.first), label.second] : [label.first, label.second]
    end

    def filter_class
      @filter_class ||= ::CostQuery::Filter.all.detect { |filter| filter.underscore_name == params[:dependent] }
    end
  end
end
