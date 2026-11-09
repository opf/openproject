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
  module Types
    class GroupedListComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable
      include WorkPackageTypes::VariantRoutes

      FRAME_ID = "admin-types-list"

      def initialize(types:, expanded_type_id: nil, page_args: {}, query: nil, created_by_migration: nil)
        super()

        @types = types
        @expanded_type_id = expanded_type_id
        @page_args = page_args.presence || { page: types.current_page, per_page: types.per_page }
        @query = query.presence
        @created_by_migration = created_by_migration.presence
      end

      private

      attr_reader :types, :expanded_type_id, :page_args, :query, :created_by_migration

      def migration_filter? = created_by_migration == "t"

      def filtered? = query.present? || migration_filter?

      def collapsed?(root)
        return false if filtered?

        root.id != expanded_type_id
      end

      def named_variants(root)
        scope = root.variants.non_default_variants
        scope = scope.with_name_like(query) if narrowed_to_query?(root)
        scope = scope.created_by_migration if migration_filter?
        scope
      end

      def narrowed_to_query?(root)
        query && root.name.downcase.exclude?(query.strip.downcase)
      end

      # Left out rather than shown as zero, so the badge never labels a type nobody has made a
      # variant of.
      def variants_count(root)
        count = named_variants(root).size
        count if count.positive?
      end

      def listed_variants(root)
        named_variants(root).global.in_display_order
      end

      def owned_variants_count(root)
        named_variants(root).project_owned.size
      end

      def owned_variants_path(root)
        type_variants_path(type_id: root.id, created_by_migration: created_by_migration)
      end

      # Only the type's own configuration: a variant carrying the flag says so on its own row.
      def add_default_label(header, type)
        return unless type.default_variant.enabled_in_new_projects?

        header.with_label { t("types.index.enabled_in_new_projects") }
      end

      def add_variant_path(type)
        new_variant_creation_wizard_path(nil, type, back_url: types_path)
      end

      def menu_id(type)
        TypeActionsComponent.menu_id(type)
      end

      def menu_src(type)
        menu_type_path(type, **context_args)
      end

      def variant_menu_id(variant)
        VariantActionsComponent.menu_id(variant)
      end

      def variant_menu_src(variant)
        menu_type_variant_path(type_id: variant.type_id, id: variant.id)
      end

      def reorderable?(type)
        !filtered? && !(type.first? && type.last?)
      end

      def context_args
        page_args.merge(expand: expanded_type_id, query:, created_by_migration:).compact
      end

      def wrapper_data_attributes
        {
          controller: "sortable-lists",
          sortable_lists_move_url_template_value: move_url_template,
          sortable_lists_sortable_lists__list_outlet: "##{wrapper_key} [data-controller~='sortable-lists--list']",
          sortable_lists_sortable_lists__item_outlet: "##{wrapper_key} [data-controller~='sortable-lists--item']"
        }
      end

      # Built from the route helper with a sentinel so relative-URL-root
      # installations keep working; {id} is expanded client-side.
      def move_url_template
        id_placeholder = "__id__"
        move_type_path(id_placeholder, **context_args).sub(id_placeholder, "{id}")
      end

      def list_data
        {
          controller: "sortable-lists--list",
          sortable_lists__list_type_value: sortable_list_type,
          sortable_lists__list_accepted_type_value: sortable_list_type,
          sortable_lists__list_name_value: t(:label_type_plural)
        }
      end

      def item_data(root)
        {
          controller: "sortable-lists--item",
          sortable_lists__item_target: "preview",
          sortable_lists__item_id_value: root.id,
          sortable_lists__item_type_value: sortable_list_type,
          sortable_lists__item_label_value: root.name,
          sortable_lists__item_mobility_value: ("fixed" unless reorderable?(root))
        }.compact
      end

      def sortable_list_type
        ::Type.model_name.param_key
      end
    end
  end
end
