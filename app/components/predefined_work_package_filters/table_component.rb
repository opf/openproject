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

module PredefinedWorkPackageFilters
  class TableComponent < OpPrimer::BorderBoxTableComponent
    columns :name, :configured_filters
    main_column :name

    def initialize(rows:, reorderable: true)
      super(rows:)
      @reorderable = reorderable
    end

    def reorderable? = @reorderable

    def headers
      [[:name, { caption: t(:label_name) }], [:configured_filters, { caption: t(:label_filter_plural) }]]
    end

    def has_actions? = true

    def mobile_title = t("predefined_work_package_filters.title")

    def container_id = "predefined-work-package-filters-table"

    def container_data
      return {} unless reorderable?

      {
        controller: "sortable-lists sortable-lists--list",
        sortable_lists_move_url_template_value: move_url_template,
        sortable_lists_sortable_lists__list_outlet: "##{container_id}",
        sortable_lists_sortable_lists__item_outlet: "##{container_id} [data-controller~='sortable-lists--item']",
        sortable_lists__list_type_value: PredefinedWorkPackageFilter::SORTABLE_LIST_TYPE,
        sortable_lists__list_accepted_type_value: PredefinedWorkPackageFilter::SORTABLE_LIST_TYPE,
        sortable_lists__list_name_value: mobile_title,
        sortable_lists__list_rows_container_element: ":scope > .#{rows_container_class}"
      }
    end

    private

    def move_url_template
      move_admin_predefined_work_package_filter_path("__id__").sub("__id__", "{id}")
    end
  end
end
