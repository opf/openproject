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
        # Lists the type families active in a project: one row per family,
        # naming the active variant behind the parent type it presents as.
        class ListComponent < ApplicationComponent
          include OpPrimer::ComponentHelpers
          include OpTurbo::Streamable

          def initialize(project:, pending_switch: nil)
            super()

            @project = project
            @pending_switch = pending_switch
          end

          private

          attr_reader :project, :pending_switch

          # A variant's acts_as_list position is scoped to its parent, so only
          # the family's own position is comparable across rows.
          def active_types
            @active_types ||= project
                                .types
                                .includes(:parent, :color)
                                .sort_by { |type| type.root.position }
          end

          def switching? = pending_switch.present?

          def switching_from?(type)
            switching? && pending_switch.source_id == type.id
          end

          # Switching to the family parent leaves the project on no variant at
          # all, so it cannot borrow the wording the mockup gives a variant.
          def switching_to_prefix
            key = pending_switch.target.variant? ? "switching_to_variant" : "switching_to_type"

            t("projects.settings.types.#{key}")
          end

          def switching_to_name
            pending_switch.target.own_name
          end

          def wrapper_data_attrs
            return {} unless switching?

            {
              data: {
                controller: "poll-for-changes",
                poll_for_changes_url_value: status_project_settings_work_packages_types_path(project),
                poll_for_changes_interval_value: 3000
              }
            }
          end

          def switch_path(type)
            new_project_settings_work_packages_type_switch_path(project, type)
          end

          def switch_action(menu, type)
            return blocked_switch_action(menu) if switching?

            menu.with_item(
              label: t("projects.settings.types.switch_type"),
              href: switch_path(type),
              content_arguments: { data: { controller: "async-dialog" } }
            ) do |item|
              item.with_leading_visual_icon(icon: "list-ordered")
            end
          end

          # Switches are serialised by an advisory lock on the project, so a
          # second one would queue behind the first. Saying so is kinder than an
          # action that silently disappears from families nobody is switching.
          def blocked_switch_action(menu)
            menu.with_item(
              label: t("projects.settings.types.switch_type"),
              disabled: true,
              description_scheme: :block
            ) do |item|
              item.with_leading_visual_icon(icon: "list-ordered")
              item.with_description { t("projects.settings.types.switch_in_progress") }
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
        end
      end
    end
  end
end
