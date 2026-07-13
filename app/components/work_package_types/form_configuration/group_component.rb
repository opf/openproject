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
    class GroupComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(group:, type: nil, ee_available: false, first: false, last: false, edit_mode: false,
                     form_model: nil)
        super(group)
        @group = group
        @type = type
        @ee_available = ee_available
        @first = first
        @last = last
        @edit_mode = edit_mode
        @form_model = form_model
        @instance_uid = SecureRandom.hex(4)
      end

      def wrapper_uniq_by
        @group[:key].presence || @instance_uid
      end

      def edit_mode?
        @edit_mode
      end

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
        {
          group_type: @group[:type].to_s,
          group_key: @group[:key].to_s,
          group_query: @group[:query],
          edit_mode: (true if edit_mode?)
        }.compact.merge(draggable_item_config)
      end

      def group_name
        @group[:name]
      end

      def temporary_group?
        @group[:temporary]
      end

      def draggable_item_config
        return {} if @group[:key].blank? || temporary_group?

        {
          "draggable-id": @group[:key],
          "draggable-type": "group",
          "drop-url": drop_type_form_configuration_group_path(@type, @group[:key])
        }
      end

      def row_drop_target_config
        return {} if query_group? || @group[:key].blank? || temporary_group?

        {
          "admin--type-form-configuration--rows-drag-and-drop-target": "container",
          "target-container-accessor": ".Box > ul",
          "target-id": @group[:key],
          "target-allowed-drag-type": "attribute"
        }
      end

      def edit_path
        edit_type_form_configuration_group_path(@type, @group[:key])
      end

      def update_path
        type_form_configuration_group_path(@type, @group[:key])
      end

      def cancel_edit_path
        cancel_edit_type_form_configuration_group_path(@type, @group[:key])
      end

      def move_path(move_to)
        move_type_form_configuration_group_path(@type, @group[:key], move_to:)
      end

      def destroy_path
        type_form_configuration_group_path(@type, @group[:key])
      end

      def row_drop_path(attribute)
        drop_type_form_configuration_row_path(@type, attribute[:key])
      end
    end
  end
end
