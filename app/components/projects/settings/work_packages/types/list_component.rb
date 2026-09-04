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

module Projects
  module Settings
    module WorkPackages
      module Types
        class ListComponent < ApplicationComponent
          include OpPrimer::ComponentHelpers
          include OpTurbo::Streamable

          def initialize(project:)
            super()

            @project = project
          end

          private

          attr_reader :project

          def active_project_types
            @active_project_types ||= project
                                        .project_types
                                        .includes(:variant, type: :color)
                                        .sort_by { |project_type| project_type.type.position }
          end

          def manages_types?
            User.current.allowed_in_project?(:manage_types, project)
          end

          def base_variant(project_type) = project_type.type.default_variant

          def switch_targets(project_type)
            @switch_targets ||= {}
            @switch_targets[project_type.id] ||=
              TypeVariant.switch_targets(user: User.current, project:, source: project_type.variant)
                         .where.not(id: project_type.variant_id)
                         .ids
          end

          # The header offers the type's own configuration, so it offers nothing once the project
          # runs on it.
          def base_type_usable?(project_type)
            usable?(project_type, base_variant(project_type))
          end

          def selectable_variants(project_type)
            project_type.type.variants.non_default_variants.available_in(project).in_display_order
          end

          def in_use?(project_type, variant)
            project_type.variant_id == variant.id
          end

          def base_type_in_use?(project_type)
            project_type.variant.default?
          end

          # Left out rather than shown as zero, so the badge never labels a type with nothing to
          # choose from.
          def variants_count(project_type)
            count = selectable_variants(project_type).size
            count if count.positive?
          end

          # Constant lookup in a compiled template does not walk the enclosing modules.
          def in_use_marker(label)
            render(InUseMarkerComponent.new(label:))
          end

          def variant_caption(variant)
            if owned?(variant)
              t("projects.settings.types.project_specific_variant")
            else
              t("projects.settings.types.variant_label")
            end
          end

          def owned?(variant)
            variant.project_id == project.id
          end

          def configurable?(variant)
            owned?(variant) && manageable?
          end

          def convertible?(variant)
            owned?(variant) && User.current.admin?
          end

          def manageable?
            User.current.allowed_in_project?(:manage_project_variants, project)
          end

          # Named explicitly: this page is not one of the variant screens, so no request carries
          # the project for it.
          def add_variant_path(type)
            new_creation_wizard_types_path(in_project_id: project, type_id: type.id)
          end

          def edit_variant_path(variant)
            edit_type_details_path(in_project_id: project, type_id: variant.type_id, variant_id: variant.id)
          end

          def delete_variant_path(variant)
            type_variant_path(in_project_id: project, type_id: variant.type_id, id: variant.id)
          end

          def actionable?(project_type, variant)
            usable?(project_type, variant) || configurable?(variant)
          end

          def usable?(project_type, variant)
            switch_targets(project_type).include?(variant.id)
          end

          def variant_actions(menu, project_type, variant)
            use_action(menu, variant) if usable?(project_type, variant)
            return unless configurable?(variant)

            edit_action(menu, variant)
            convert_action(menu, variant) if convertible?(variant)
            menu.with_divider
            delete_action(menu, variant)
          end

          def edit_action(menu, variant)
            menu.with_item(label: t(:button_edit), href: edit_variant_path(variant)) do |entry|
              entry.with_leading_visual_icon(icon: :pencil)
            end
          end

          # Converting is a global operation, so it doesn't pass in_project_id
          def convert_action(menu, variant)
            args = { type_id: variant.type_id, id: variant.id }
            trigger = if variant.inherits_from_project_owned_variant?
                        { href: convert_to_global_type_variant_path(**args), form_arguments: { method: :post } }
                      else
                        { href: convert_to_global_dialog_type_variant_path(**args),
                          content_arguments: { data: { controller: "async-dialog" } } }
                      end

            menu.with_item(label: t("types.index.convert_to_global"), **trigger) do |entry|
              entry.with_leading_visual_icon(icon: :"git-compare")
            end
          end

          def delete_action(menu, variant)
            menu.with_item(
              label: t(:button_delete),
              scheme: :danger,
              href: delete_variant_path(variant),
              form_arguments: { method: :delete }
            ) do |entry|
              entry.with_leading_visual_icon(icon: :trash)
            end
          end

          # The reader has already chosen on the row, so the dialog opens on that variant.
          def use_action(menu, variant)
            menu.with_item(
              label: t("projects.settings.types.use_in_project"),
              href: switch_path(variant),
              content_arguments: { data: { controller: "async-dialog" } }
            ) do |entry|
              entry.with_leading_visual_icon(icon: "check-circle")
            end
          end

          def add_variant_action(menu, type)
            menu.with_item(label: t("projects.settings.types.add_variant"), href: add_variant_path(type)) do |item|
              item.with_leading_visual_icon(icon: :plus)
            end
          end

          def type_actions?(project_type)
            manageable? || base_type_usable?(project_type) || manages_types?
          end

          def removal_set_apart?(project_type)
            manages_types? && (manageable? || base_type_usable?(project_type))
          end

          def switch_path(variant)
            new_project_settings_work_packages_type_switch_path(project, variant.type, target_id: variant.id)
          end

          def remove_path(type)
            project_settings_work_packages_type_path(project, type)
          end

          def remove_action(menu, type)
            menu.with_item(
              label: t("projects.settings.types.remove_from_project"),
              scheme: :danger,
              href: remove_path(type),
              form_arguments: { method: :delete }
            ) do |item|
              item.with_leading_visual_icon(icon: :trash)
            end
          end
        end
      end
    end
  end
end
