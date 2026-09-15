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
  module ReuseMode
    class ModeBoxComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      INHERITED_ICON = :"arrow-down-right"
      MANUAL_ICON = :tools

      def initialize(variant:, aspect:)
        @aspect = aspect
        super(variant)
      end

      private

      attr_reader :aspect

      def variant = model

      def linked? = variant.linked?(aspect)

      def group_data
        { controller: "mode-switch-radio", action: "change->mode-switch-radio#select" }
      end

      def inherited_option
        {
          value: "inherited",
          checked: linked?,
          label: inherited_label,
          title_link: inherited_title_link,
          caption: t("types.edit.reuse_mode.inherited.mode_description"),
          leading_icon: INHERITED_ICON,
          action: {
            text: t("types.edit.reuse_mode.inherited.change_source"),
            href: link_dialog_path,
            data: { controller: "async-dialog", test_selector: "reuse-mode-change-source" }
          },
          data: {
            "mode-switch-radio-target": "radio",
            "dialog-url": link_dialog_path,
            test_selector: "reuse-mode-option-inherited"
          }
        }
      end

      def manual_option
        {
          value: "manual",
          checked: !linked?,
          label: t("types.edit.reuse_mode.manual.title"),
          caption: t("types.edit.reuse_mode.manual.mode_description"),
          leading_icon: MANUAL_ICON,
          action: manual_action,
          data: {
            "mode-switch-radio-target": "radio",
            "dialog-url": independent_dialog_path,
            test_selector: "reuse-mode-option-manual"
          }
        }
      end

      def manual_action
        return nil unless copy_supported?

        {
          text: t("types.edit.reuse_mode.manual.copy_from_type"),
          href: copy_dialog_path,
          data: { controller: "async-dialog", test_selector: "reuse-mode-copy-from-variant" }
        }
      end

      def inherited_label
        if inherited_title_link
          t("types.edit.reuse_mode.inherited.mode_label_with_source")
        else
          t("types.edit.reuse_mode.inherited.mode_label")
        end
      end

      def inherited_title_link
        return nil unless linked? && source_path

        {
          text: "#{source.composite_name}#{parent_suffix}",
          href: source_path,
          data: { turbo_frame: "_top" }
        }
      end

      def source = variant.source_for(aspect)

      def source_is_default? = source.present? && source == variant.type.default_variant

      def source_path
        return nil unless source_reachable?

        helpers.aspect_edit_path(source, aspect)
      end

      def source_reachable?
        return false if source.nil?
        return true if helpers.variant_scope_project.nil?

        source.project_id == helpers.variant_scope_project.id
      end

      def copy_supported? = CopyConfiguration.supported?(aspect)

      def copy_dialog_path = type_configuration_copy_dialog_path(**dialog_path_args)

      def link_dialog_path = type_configuration_link_dialog_path(**dialog_path_args)

      def independent_dialog_path = type_configuration_independence_dialog_path(**dialog_path_args)

      def dialog_path_args = variant.path_args.merge(aspect:)

      def parent_suffix
        source_is_default? ? I18n.t("types.edit.reuse_mode.parent_suffix") : ""
      end
    end
  end
end
