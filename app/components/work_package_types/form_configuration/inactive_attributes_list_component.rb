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
    class InactiveAttributesListComponent < ApplicationComponent
      include OpTurbo::Streamable
      include AttributeItemData

      def initialize(context:, inactive_attributes:)
        super
        @context = context
        @inactive_attributes = inactive_attributes
      end

      private

      def container_data
        {
          "test-selector": "type-form-configuration-inactive-container",
          "admin--type-form-configuration--main-target": "inactiveContainer",
          controller: "sortable-lists--list",
          sortable_lists__list_type_value: SortableTypes::INACTIVE_ATTRIBUTE,
          sortable_lists__list_accepted_type_value: SortableTypes::ATTRIBUTE,
          sortable_lists__list_name_value: t("types.edit.form_configuration.inactive_attributes_heading"),
          sortable_lists__list_rows_container_element: ".type-form-configuration-page--inactive-list"
        }
      end

      def item_data(attribute)
        merge_data(
          { data: attribute_item_data(attribute) },
          { data: { "filter--filter-list-target": "searchItem" } }
        )
      end
    end
  end
end
