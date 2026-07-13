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

module WorkPackageTypes
  module FormConfiguration
    class InactiveAttributesListComponent < ApplicationComponent
      include OpTurbo::Streamable

      def initialize(type:, inactive_attributes:)
        super
        @type = type
        @inactive_attributes = inactive_attributes
      end

      private

      def container_data
        {
          "test-selector": "type-form-configuration-inactive-container",
          "admin--type-form-configuration--main-target": "inactiveContainer",
          "admin--type-form-configuration--rows-drag-and-drop-target": "container",
          "target-container-accessor": "[data-test-selector='type-form-configuration-inactive-list']",
          "target-id": "inactive",
          "target-allowed-drag-type": "attribute"
        }
      end

      def item_data(attribute)
        {
          attr_key: attribute[:key],
          attr_translation: attribute[:translation],
          attr_is_cf: attribute[:is_cf],
          "draggable-id": attribute[:key],
          "draggable-type": "attribute",
          "drop-url": drop_type_form_configuration_row_path(@type, attribute[:key])
        }
      end
    end
  end
end
