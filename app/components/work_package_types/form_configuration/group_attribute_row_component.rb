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
    class GroupAttributeRowComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(attribute:, variant:, index:, total_count:, readonly: false, exclusions: nil)
        super
        @attribute = attribute
        @variant = variant
        @index = index
        @total_count = total_count
        @readonly = readonly
        @exclusions = exclusions
      end

      def readonly?
        @readonly
      end

      def required_label
        if @attribute[:required_globally]
          t("types.edit.form_configuration.required.globally")
        elsif @attribute[:required_for_variant]
          t("types.edit.form_configuration.required.for_variant")
        end
      end

      def required_label_scheme
        @attribute[:required_globally] ? :attention : :severe
      end

      def show_required_action?
        !readonly? && @attribute[:is_cf]
      end

      def required_action_disabled?
        @attribute[:required_globally].present?
      end

      def toggle_required_label
        key = @attribute[:required_for_variant] ? "unmark" : "mark"

        t("types.edit.form_configuration.required.#{key}")
      end

      def toggle_required_icon
        @attribute[:required_for_variant] ? "circle-slash" : "circle"
      end

      def toggle_required_hint
        t("types.edit.form_configuration.required.globally_hint")
      end

      def toggle_required_item_arguments
        arguments = {
          label: toggle_required_label,
          disabled: required_action_disabled?,
          test_selector: "type-form-configuration-toggle-required-#{@attribute[:key]}"
        }
        return arguments if required_action_disabled?

        arguments.merge(
          tag: :a,
          href: row_toggle_required_path,
          content_arguments: { data: { turbo_method: :put, turbo_stream: true } }
        )
      end

      def row_toggle_required_path
        toggle_required_type_form_configuration_row_path(type_id: @variant.type_id, variant_id: @variant.id,
                                                         row_key: @attribute[:key])
      end

      def exclusion_toggle
        @exclusion_toggle ||= ExclusionToggleComponent.new(
          exclusions: @exclusions,
          element_key: @attribute[:key],
          label: t("types.edit.form_configuration.exclusions.attribute_label", attribute: @attribute[:translation])
        )
      end

      private

      def multiple_attributes?
        @total_count > 1
      end

      def attribute_can_move_up?
        multiple_attributes? && !@index.zero?
      end

      def attribute_can_move_down?
        multiple_attributes? && @index != @total_count - 1
      end

      def show_delete_divider?
        attribute_can_move_up? || attribute_can_move_down? || show_required_action?
      end

      def row_move_path(move_to)
        move_type_form_configuration_row_path(type_id: @variant.type_id, variant_id: @variant.id, row_key: @attribute[:key],
                                              move_to:)
      end

      def row_destroy_path
        type_form_configuration_row_path(type_id: @variant.type_id, variant_id: @variant.id, row_key: @attribute[:key])
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
