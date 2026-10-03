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
      include SortableLists::MoveMenu

      def initialize(attribute:, context:, total_count:)
        super
        @attribute = attribute
        @context = context
        @total_count = total_count
      end

      delegate :readonly?, to: :@context

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
        @context.toggles_required? && @attribute[:is_cf]
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
        @context.toggle_required_path(@attribute[:key])
      end

      def exclusion_toggle
        @exclusion_toggle ||= ExclusionToggleComponent.new(
          exclusions: @context.exclusions,
          element_key: @attribute[:key],
          label: t("types.edit.form_configuration.exclusions.attribute_label", attribute: @attribute[:translation])
        )
      end

      private

      def multiple_attributes?
        @total_count > 1
      end

      def actions_button_arguments
        {
          icon: "kebab-horizontal",
          scheme: :invisible,
          size: :small,
          classes: "type-form-configuration-page--actions-button",
          test_selector: "type-form-configuration-attribute-actions-#{@attribute[:key]}",
          "aria-label": t("types.edit.form_configuration.row_actions")
        }
      end

      def row_destroy_path
        @context.row_path(row_key: @attribute[:key])
      end
    end
  end
end
