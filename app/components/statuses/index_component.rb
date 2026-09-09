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

module Statuses
  class IndexComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    options :statuses
    options :query
    options :page_args

    private

    # The list may show one page of statuses while positions run across all of them.
    def max_position
      Status.maximum(:position)
    end

    # Positions are global while a filtered list shows a non-contiguous subset, so a
    # drop would resolve against neighbours the list does not display.
    def reorderable?
      query.filters.empty?
    end

    def empty_state_title
      if reorderable?
        t("statuses.index.no_results_title_text")
      else
        t("statuses.index.no_filter_results_title_text")
      end
    end

    def empty_state_description
      t("statuses.index.no_results_content_text") if reorderable?
    end

    def wrapper_data_attributes
      return {} unless reorderable?

      {
        controller: "sortable-lists",
        sortable_lists_move_url_template_value: move_url_template,
        sortable_lists_sortable_lists__list_outlet: "##{wrapper_key} [data-controller~='sortable-lists--list']",
        sortable_lists_sortable_lists__item_outlet: "##{wrapper_key} [data-controller~='sortable-lists--item']"
      }
    end

    def move_url_template
      id_placeholder = "__id__"
      move_status_path(id_placeholder, **page_args.to_h).sub(id_placeholder, "{id}")
    end

    def drop_target_config
      return {} unless reorderable?

      {
        controller: "sortable-lists--list",
        sortable_lists__list_type_value: Status::SORTABLE_LIST_TYPE,
        sortable_lists__list_accepted_type_value: Status::SORTABLE_LIST_TYPE,
        sortable_lists__list_name_value: t(:label_status_plural)
      }
    end

    def draggable_item_config(status)
      return {} unless reorderable?

      {
        controller: "sortable-lists--item",
        sortable_lists__item_id_value: status.id,
        sortable_lists__item_type_value: Status::SORTABLE_LIST_TYPE,
        sortable_lists__item_label_value: status.name
      }
    end
  end
end
