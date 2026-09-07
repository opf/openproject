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
  module Types
    class VariantActionsComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def self.menu_id(variant)
        "variant-#{variant.id}-action-menu"
      end

      def initialize(variant:, back_url: nil)
        super()

        @variant = variant
        @back_url = back_url
      end

      def menu_id
        self.class.menu_id(variant)
      end

      private

      attr_reader :variant, :back_url

      def variant_actions(menu)
        configure_action(menu)
        default_action(menu)
        menu.with_divider

        delete_action(menu)
      end

      def configure_action(menu)
        menu.with_item(
          label: t(:button_configure),
          href: edit_type_details_path(type_id: variant.type_id, variant_id: variant.id)
        ) do |item|
          item.with_leading_visual_icon(icon: :gear)
        end
      end

      # A new project cannot start on a variant a project owns: it would be a configuration only
      # that project can see.
      def default_action(menu)
        return if variant.project_owned?

        if variant.enabled_in_new_projects?
          remove_default_action(menu)
        else
          make_default_action(menu)
        end
      end

      def make_default_action(menu)
        menu.with_item(
          label: t("types.index.make_default"),
          href: make_default_type_variant_path(type_id: variant.type_id, id: variant.id, back_url:),
          form_arguments: { method: :post }
        ) do |item|
          item.with_leading_visual_icon(icon: :"check-circle")
        end
      end

      def remove_default_action(menu)
        menu.with_item(
          label: t("types.index.remove_default"),
          href: remove_default_type_variant_path(type_id: variant.type_id, id: variant.id, back_url:),
          form_arguments: { method: :post }
        ) do |item|
          item.with_leading_visual_icon(icon: :"circle-slash")
        end
      end

      def delete_action(menu)
        if variant.project_types.exists?
          delete_with_migration_action(menu)
        else
          simple_delete_action(menu)
        end
      end

      def delete_with_migration_action(menu)
        menu.with_item(
          label: t(:button_delete),
          scheme: :danger,
          href: deletion_dialog_type_variant_path(type_id: variant.type_id, id: variant.id),
          content_arguments: { data: { controller: "async-dialog" } }
        ) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end

      def simple_delete_action(menu)
        menu.with_item(
          label: t(:button_delete),
          scheme: :danger,
          href: type_variant_path(type_id: variant.type_id, id: variant.id, back_url:),
          form_arguments: { method: :delete, data: { turbo_confirm: t(:text_are_you_sure) } }
        ) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end
    end
  end
end
