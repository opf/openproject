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

module WorkPackageTypes
  module FormConfiguration
    class GroupComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include AttributeItemData

      def initialize(group:, context:, ee_available: false, first: false, last: false, edit_mode: false,
                     form_model: nil)
        super(group)
        @group = group
        @context = context
        @ee_available = ee_available
        @first = first
        @last = last
        @edit_mode = edit_mode
        @form_model = form_model
        @instance_uid = SecureRandom.hex(4)
      end

      def wrapper_uniq_by
        @group[:id].presence || @group[:key].presence || @instance_uid
      end

      def edit_mode?
        @edit_mode
      end

      delegate :readonly?, :exclusions, to: :@context

      def query_group?
        @group[:type].to_s == "query"
      end

      def attributes
        @group[:attributes] || []
      end

      def first?
        @first
      end

      def last?
        @last
      end

      def ee_available?
        @ee_available
      end

      private

      def wrapper_data
        data = {
          group_type: @group[:type].to_s,
          group_key: @group[:key].to_s,
          group_query: @group[:query],
          update_query_url: update_query_path,
          edit_mode: (true if edit_mode?)
        }.compact

        merge_data({ data: }, { data: item_data })
      end

      def group_name
        @group[:name]
      end

      def temporary_group?
        @group[:temporary]
      end

      def sortable?
        !readonly? && @group[:id].present? && !temporary_group?
      end

      def item_data
        return {} unless sortable?

        {
          controller: "sortable-lists--item",
          sortable_lists__item_id_value: @group[:id],
          sortable_lists__item_type_value: SortableTypes::GROUP,
          sortable_lists__item_label_value: group_name,
          sortable_lists__item_mobility_value: ("fixed" if edit_mode?)
        }.compact
      end

      def box_data
        return {} unless sortable?

        preview = { sortable_lists__item_target: "preview" }
        return preview if query_group?

        merge_data(
          { data: preview },
          {
            data: {
              controller: "sortable-lists--list",
              sortable_lists__list_type_value: SortableTypes::ATTRIBUTE,
              sortable_lists__list_accepted_type_value: SortableTypes::ATTRIBUTE,
              sortable_lists__list_id_value: @group[:id],
              sortable_lists__list_name_value: group_name
            }
          }
        )
      end

      def row_data(attribute)
        return {} if readonly?

        attribute_item_data(attribute)
      end

      def update_query_path
        @context.group_path(:update_query, key: @group[:key])
      end
    end
  end
end
