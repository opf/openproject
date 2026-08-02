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
    class GroupedListComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(types:, expanded_type_id: nil)
        super()

        @types = types
        @expanded_type_id = expanded_type_id
      end

      private

      attr_reader :types, :expanded_type_id

      def collapsed?(root)
        root.id != expanded_type_id
      end

      def variants_count_label(root)
        t("types.index.variants_count", count: root.children.size)
      end

      # A default variant is only visible once the group is expanded, so the
      # collapsed header names it instead.
      def add_default_label(header, root)
        if root.is_default?
          header.with_action_label { t("types.index.enabled_in_new_projects") }
        elsif (variant = default_variant(root))
          header.with_action_label(scheme: :secondary) do
            t("types.index.variant_enabled_in_new_projects", name: variant.own_name)
          end
        end
      end

      def default_variant(root)
        root.children.find(&:is_default?)
      end

      def add_variant_path(root)
        new_creation_wizard_types_path(parent_id: root.id)
      end

      def menu_id(type)
        TypeActionsComponent.menu_id(type)
      end

      def menu_src(type)
        menu_type_path(type)
      end

      def reorderable?(type)
        !type.variant? && !(type.first? && type.last?)
      end

      def drop_target_config
        {
          generic_drag_and_drop_target: "container",
          "target-allowed-drag-type": "work-package-type"
        }
      end

      def draggable_item_config(root)
        {
          "draggable-type": "work-package-type",
          "draggable-id": root.id,
          "drop-url": drop_type_path(root)
        }
      end
    end
  end
end
