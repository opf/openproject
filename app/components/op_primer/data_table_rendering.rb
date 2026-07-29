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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpPrimer
  # Renders a legacy +TableComponent+ DSL through
  # +Primer::OpenProject::DataTable+.
  #
  # Included by the two compatibility façades. Everything that differs between
  # the generic and the BorderBox flavours is expressed as an overridable hook:
  # {#data_table_title}, {#empty_state_arguments}, {#cell_classes_for},
  # {#column_arguments_for} and {#data_table_footer}.
  #
  # == The three values of a column
  #
  # Every column carries three distinct values, and they are *not*
  # interchangeable:
  #
  # +column+::  the entry from +#columns+. For most tables a Symbol; for
  #             query-driven tables (+Users+, +Members+, ...) a
  #             +Queries::Selects+ object. Feeds +render_only:+,
  #             +column_css_class+, +mobile_columns+ and +main_column?+.
  # +id+::      the key from the matching +#headers+ entry. Always a String or
  #             Symbol. Feeds +with_column(id:)+, +sortable_column?+ and the
  #             sort URL. +sortable_column?+ calls +#to_sym+, which raises on a
  #             +Queries::Selects+ object — so it must never be handed +column+.
  # +options+:: the header options Hash: +:caption+ and optionally
  #             +:default_order+.
  module DataTableRendering
    def call
      component_wrapper do
        render(data_table) { |table| configure_data_table(table) } + data_table_footer.to_s
      end
    end

    # Pairs each entry of +#columns+ with its +#headers+ entry.
    #
    # Resolves by key first, which is the invariant +BorderBoxTableComponent#column_title+
    # already relies on, and falls back to position, which is guaranteed by
    # construction for the query-driven tables that build +headers+ by mapping
    # over +columns+.
    def data_table_columns
      entries = headers

      unless entries.size == columns.size
        raise ArgumentError,
              "#{self.class.name}: headers (#{entries.size}) and columns (#{columns.size}) must correspond"
      end

      columns.each_with_index.map do |column, index|
        id, options = entries.assoc(column) || entries[index]
        [column, id, options]
      end
    end

    # Title rendered above the table. Nil renders no title.
    def data_table_title
      nil
    end

    # Arguments forwarded to the DataTable's empty state slot.
    def empty_state_arguments
      { title: empty_row_message }
    end

    # Content rendered after the table. +has_footer?+ is a BorderBox-only
    # method, so the generic façade must not reach for it.
    def data_table_footer
      nil
    end

    # Proc supplying per-row CSS classes for a column's cell.
    def cell_classes_for(column)
      ->(row) { row_class.new(row: row, table: self).column_css_class(column) }
    end

    # Extra per-column arguments. Overridden by the responsive façade.
    def column_arguments_for(_column)
      {}
    end

    # Root CSS class, giving downstream stylesheets something to scope to.
    def data_table_classes
      nil
    end

    private

    def configure_data_table(table)
      add_data_table_title(table)
      data_table_columns.each { |column, id, options| add_data_table_column(table, column, id, options) }
      add_actions_column(table) if has_actions?
      table.with_empty_state(**empty_state_arguments) if rows.empty?
      add_pagination(table)
    end

    def add_data_table_title(table)
      title = data_table_title
      table.with_title { title } if title.present?
    end

    def data_table
      Primer::OpenProject::DataTable.new(
        rows,
        classes: data_table_classes,
        sorting: sortable? ? :external : :client,
        sort_href_builder: (sort_href_builder if sortable?),
        initial_sort_column: initial_sort_column,
        initial_sort_direction: initial_sort_direction,
        row_classes: ->(row) { row_class.new(row: row, table: self).row_css_class },
        row_data: ->(row) { row_class.new(row: row, table: self).row_data }
      )
    end

    def add_data_table_column(table, column, id, options)
      table.with_column(
        id: id.to_s,
        header: options[:caption],
        sort_by: sortable_column?(id) || nil,
        cell_classes: cell_classes_for(column),
        **column_arguments_for(column)
      ) do |data_table_column|
        data_table_column.with_cell { |row| render(row_class.new(row: row, table: self, render_only: column)) }
      end
    end

    def add_actions_column(table)
      table.with_column(
        id: "actions",
        header: helpers.content_tag(:span, I18n.t(:label_actions), class: "sr-only"),
        cell_classes: ->(_row) { "op-data-table--actions-column" }
      ) do |column|
        column.with_cell do |row|
          render(row_class.new(row: row, table: self, render_only: ::RowComponent::ACTIONS_CELL))
        end
      end
    end

    def add_pagination(table)
      return unless paginated?
      # An empty will_paginate collection reports total_pages == 0, and
      # Primer::OpenProject::Pagination raises at initialize when
      # current_page > page_count.
      return unless rows.total_entries.to_i.positive?
      return if rows.current_page > rows.total_pages

      table.with_pagination(**pagination_arguments)
    end

    def pagination_arguments
      {
        current_page: rows.current_page,
        page_count: rows.total_pages,
        total_count: rows.total_entries,
        page_size: rows.per_page,
        href_builder: ->(page) { helpers.url_for(request.query_parameters.merge(page: page)) }
      }
    end

    # Delegates to SortHelper so multi-column state, the parameter whitelist and
    # the deliberate omission of +page+ are all inherited rather than reinvented.
    # The direction DataTable proposes is ignored: it hard-codes NONE -> ASC,
    # which would lose per-column +default_order+.
    def sort_href_builder
      lambda do |column_id, _direction|
        helpers.url_for(helpers.sort_by_options(column_id, nil, default_order_for(column_id)))
      end
    end

    def default_order_for(column_id)
      _, options = headers.find { |name, _| name.to_s == column_id.to_s }
      options&.dig(:default_order)
    end

    # +SortCriteria#criteria+ stores [key, ascending] pairs, where the direction
    # is a Boolean: true for ascending and false for descending.
    def current_sort_criterion
      sort_criteria&.criteria&.first
    end

    def initial_sort_column
      return unless sortable?

      current_sort_criterion&.first&.to_s
    end

    def initial_sort_direction
      return unless sortable?

      criterion = current_sort_criterion
      return unless criterion

      criterion.last ? :ASC : :DESC
    end
  end
end
