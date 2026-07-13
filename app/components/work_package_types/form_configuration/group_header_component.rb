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
    class GroupHeaderComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(group:, type:, ee_available:, first:, last:, edit_mode:, form_model: nil)
        super
        @group = group
        @type = type
        @ee_available = ee_available
        @first = first
        @last = last
        @edit_mode = edit_mode
        @form_model = form_model
      end

      def edit_mode?
        @edit_mode
      end

      private

      def group_name
        @group[:name]
      end

      def form_model
        @form_model || WorkPackageTypes::FormConfiguration::GroupFormModel.from_group(@group)
      end

      def ee_available?
        @ee_available
      end

      def first?
        @first
      end

      def last?
        @last
      end

      def edit_path
        edit_type_form_configuration_group_path(@type, @group[:key])
      end

      def update_path
        return create_path if temporary_group?

        type_form_configuration_group_path(@type, @group[:key])
      end

      def form_method
        temporary_group? ? :post : :patch
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

      def temporary_group?
        @group[:temporary]
      end

      def create_path
        type_form_configuration_groups_path(@type)
      end

      def move_action(menu:, href:, label:, icon:)
        menu.with_item(
          label:,
          tag: :a,
          href:,
          content_arguments: { data: { turbo_method: :put, turbo_stream: true } }
        ) do |item|
          item.with_leading_visual_icon(icon:)
        end
      end
    end
  end
end
