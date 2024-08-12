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

module Grids::Copy
  class WidgetsDependentService < ::Copy::Dependency
    protected

    def copy_dependency(params:)
      copy_widgets source, target, params
    end

    def copy_widgets(grid, new_grid, params)
      grid.widgets.find_each do |widget|
        new_widget = duplicate_widget widget, new_grid, params

        if new_widget && !new_widget.save
          add_error! new_widget, new_widget.errors, model_name: widget_model_name(widget)
        end
      end
    end

    def duplicate_widget(widget, new_grid, params)
      new_widget = widget.dup
      new_widget.grid = new_grid

      references = map_references(widget, params).each do |result|
        if result.success?
          result.each do |option, value|
            new_widget.options[option] = value
          end
        else
          add_error! widget, result.errors, model_name: widget_model_name(widget)
        end
      end

      new_widget if references.all?(&:success?)
    end

    # Provide a human readable name for the widget
    def widget_model_name(widget)
      I18n.t("grids.label_widget_in_grid", grid_name: widget.grid.to_s)
    end

    def map_references(widget, params)
      widget.options.map do |option, value|
        map_reference option, value, params
      end
    end

    def map_reference(option, value, params)
      mapper = find_mapper option

      if mapper
        mapper.call(value, params).map { |id| [option, id] }
      else
        ServiceResult.success result: [option, value]
      end
    end

    def find_mapper(option)
      _, mapper = reference_mappers.find do |key, _|
        (key.is_a?(Regexp) && option.to_s =~ key) || key.to_s.downcase == option.to_s.downcase
      end

      mapper
    end

    def reference_mappers
      {
        /query_?id/i => method(:map_query_id),
        filters: method(:map_query_filters)
      }
    end

    def map_query_id(query_id, params)
      existing_query_id = state.query_id_lookup[query_id.to_i] if state.query_id_lookup

      if existing_query_id
        ServiceResult.success(result: existing_query_id)
      else
        duplicate_query(query_id, params).map(&:id)
      end
    end

    def map_query_filters(filters, _params)
      ::Queries::Copy::FiltersMapper
        .new(state, filters)
        .map_filters!

      ServiceResult.success result: filters
    end

    def duplicate_query(query_id, params)
      query = Query.find query_id

      ::Queries::CopyService
        .new(user:, source: query)
        .with_state(state)
        .call(params)
    end
  end
end
