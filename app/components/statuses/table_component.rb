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

module Statuses
  class TableComponent < OpPrimer::BorderBoxTableComponent
    columns :name, :done_ratio, :closed, :readonly
    main_column :name
    mobile_columns :name

    options :query
    options :page_args

    def headers
      [
        [:name, { caption: Status.human_attribute_name(:name) }],
        ([:done_ratio, { caption: WorkPackage.human_attribute_name(:done_ratio) }] if show_done_ratio?),
        [:closed, { caption: t("statuses.index.headers.is_closed") }],
        [:readonly, { caption: t("statuses.index.headers.is_readonly") }]
      ].compact
    end

    def skip_column?(column)
      column == :done_ratio && !show_done_ratio?
    end

    def has_actions? = true

    def mobile_title = t(:label_status_plural)

    def container_id = "statuses-table"

    def container_class = "op-statuses-table"

    # Positions are global while a filtered list shows a non-contiguous subset, so a
    # drop would resolve against neighbours the list does not display.
    def reorderable?
      query.filters.empty?
    end

    def container_data
      return {} unless reorderable?

      {
        controller: "sortable-lists sortable-lists--list",
        sortable_lists_move_url_template_value: move_url_template,
        sortable_lists_sortable_lists__list_outlet: "##{container_id}",
        sortable_lists_sortable_lists__item_outlet: "##{container_id} [data-controller~='sortable-lists--item']",
        sortable_lists__list_type_value: Status::SORTABLE_LIST_TYPE,
        sortable_lists__list_accepted_type_value: Status::SORTABLE_LIST_TYPE,
        sortable_lists__list_name_value: t(:label_status_plural),
        sortable_lists__list_rows_container_element: ":scope > .#{rows_container_class}"
      }
    end

    # The list may show one page of statuses while positions run across all of them.
    def max_position
      @max_position ||= Status.maximum(:position)
    end

    def blank_icon = :alert

    def blank_title
      if reorderable?
        t("statuses.index.no_results_title_text")
      else
        t("statuses.index.no_filter_results_title_text")
      end
    end

    def blank_description
      t("statuses.index.no_results_content_text") if reorderable?
    end

    private

    # Built from the route helper with a sentinel so relative-URL-root
    # installations keep working; {id} is expanded client-side.
    def move_url_template
      id_placeholder = "__id__"
      move_status_path(id_placeholder, **page_args.to_h).sub(id_placeholder, "{id}")
    end

    def show_done_ratio?
      WorkPackage.status_based_mode?
    end
  end
end
