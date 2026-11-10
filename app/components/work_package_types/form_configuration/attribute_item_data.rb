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
    module AttributeItemData
      include OpPrimer::AttributesHelper

      private

      def attribute_item_data(attribute)
        merge_data(
          { data: { attr_key: attribute[:key], attr_translation: attribute[:translation], attr_is_cf: attribute[:is_cf] } },
          { data: sortable_attribute_data(attribute) }
        )
      end

      def sortable_attribute_data(attribute)
        return {} unless sortable_attribute?(attribute)

        {
          controller: "sortable-lists--item",
          sortable_lists__item_id_value: attribute[:id],
          sortable_lists__item_type_value: SortableTypes::ATTRIBUTE,
          sortable_lists__item_label_value: attribute[:translation]
        }
      end

      # Only attributes backed by a form attribute record can be moved, as
      # moves address that record. A read-only editor loads no records.
      def sortable_attribute?(attribute)
        attribute[:id].present?
      end
    end
  end
end
