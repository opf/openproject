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
        # The type families active in a project, each expandable to the variants the
        # project may use: the global ones plus the ones it owns. One list answers both
        # "what applies here" and "what do we own".
        class ListComponent < ApplicationComponent
          include OpPrimer::ComponentHelpers
          include OpTurbo::Streamable

          def initialize(project:)
            super()

            @project = project
          end

          private

          attr_reader :project

          # One row per family. A project uses the root and resolves the variant
          # separately, so the row is the join record rather than a single type.
          def active_project_types
            @active_project_types ||= project
                                        .project_types
                                        .includes(:variant, type: :color)
                                        .sort_by { |project_type| project_type.type.position }
          end

          # A family whose only variants belong to other projects offers this one nothing.
          def switchable?(project_type)
            project_type.type.variants_available_in(project).any?
          end

          def switch_path(type)
            new_project_settings_work_packages_type_switch_path(project, type)
          end

          def switch_action(menu, type)
            menu.with_item(
              label: t("projects.settings.types.switch_type"),
              href: switch_path(type),
              content_arguments: { data: { controller: "async-dialog" } }
            ) do |item|
              item.with_leading_visual_icon(icon: "list-ordered")
            end
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

          def variants_for(project_type)
            project_type.type.variants_available_in(project)
          end

          def in_use?(project_type, member)
            project_type.effective_type == member
          end

          def owned?(variant)
            variant.project_id == project.id
          end

          # Only a variant this project owns is one it may configure; the global ones
          # belong to administration.
          def manageable?
            User.current.allowed_in_project?(:manage_project_variants, project)
          end

          def add_variant_path(root)
            new_creation_wizard_project_settings_work_packages_types_variants_path(project, parent_id: root.id)
          end

          def edit_variant_path(variant)
            edit_project_settings_work_packages_types_variant_details_path(project, variant)
          end

          def delete_variant_path(variant)
            project_settings_work_packages_types_variant_path(project, variant)
          end
        end
      end
    end
  end
end
