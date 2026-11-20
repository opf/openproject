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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  class PredefinedFilterQuery
    attr_reader :filter, :project

    def initialize(filter, project: nil)
      @filter = filter
      @project = project
    end

    def build
      build_query(editor_properties)
    end

    def configuration_query
      properties = editor_properties
      build_query(properties).tap do |query|
        query.column_names = Array(properties["c"]).grep(String).map do |column|
          API::Utilities::WpPropertyNameConverter.to_ar_name(column)
        end
        query.timestamps = configuration_timestamps(properties["ts"])
      end
    end

    def editor_properties
      properties_for(:work_packages)
    end

    def menu_params(placement)
      builtin = builtin_params(placement)
      return builtin if filter.builtin? && filter.query_properties.empty? && builtin.present?
      return if filter.builtin? && builtin.blank? && unavailable_builtin?(placement)

      { query_props: properties_for(placement).to_json, name: "predefined_filter_#{filter.id}" }
    end

    private

    def build_query(properties)
      Query.new(project:, name: filter.display_name, include_subprojects: false).tap do |query|
        apply_grouping(query, properties["g"])
        apply_sorting(query, properties["t"])
        apply_filters(query, properties["f"])
      end
    end

    def configuration_timestamps(value)
      Timestamp.parse_multiple(value)
    rescue ArgumentError
      []
    end

    def apply_grouping(query, group)
      return if group.blank?

      query.group_by = API::Utilities::WpPropertyNameConverter.to_ar_name(group)
      query.show_hierarchies = false
    end

    def apply_sorting(query, sorting)
      query.set_default_sort
      return if sorting.blank?

      query.sort_criteria = sorting.split(",").map do |sort|
        column, direction = sort.split(":")
        [API::Utilities::WpPropertyNameConverter.to_ar_name(column), direction]
      end
    end

    def apply_filters(query, filters)
      Array(filters).each do |entry|
        name = API::Utilities::QueryFiltersNameConverter.to_ar_name(entry.fetch("n"), refer_to_ids: true)
        query.add_filter(name, entry.fetch("o"), Array(entry["v"]))
      end
    end

    def properties_for(placement)
      defaults_for(placement).merge(builtin_properties(placement)).merge(filter.query_properties).tap do |properties|
        properties["hi"] = false if properties["g"].present?
        properties["tv"] = true if placement == :gantt
      end
    end

    def defaults_for(placement)
      return Gantt::DefaultQueryGeneratorService.add_columns(project) if placement == :gantt

      { "f" => [{ "n" => "status", "o" => "o", "v" => [] }] }
    end

    def builtin_properties(placement)
      source = builtin_params(placement).to_h[:query_props]
      source ||= builtin_params(:work_packages).to_h[:query_props] if %i[gantt calendar].include?(placement)
      source ? JSON.parse(source) : {}
    end

    def builtin_params(placement)
      return unless filter.builtin?

      builtin_generator(placement)&.new(with_project: project)&.call(query_key: filter.builtin_key.to_sym)
    end

    def unavailable_builtin?(placement)
      generator = builtin_generator(placement)
      generator && generator::QUERY_OPTIONS.include?(filter.builtin_key.to_sym)
    end

    def builtin_generator(placement)
      case placement
      when :work_packages, :project_overview
        WorkPackages::DefaultQueryGeneratorService
      when :gantt
        Gantt::DefaultQueryGeneratorService
      end
    end
  end
end
