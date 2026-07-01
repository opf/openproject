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

module ResourcePlanners
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    delegate :current_project, to: :table
    delegate :project, to: :model

    def name
      icon = if model.favorited_by?(User.current)
               render(Primer::Beta::Octicon.new(
                        icon: :"star-fill",
                        "aria-label": I18n.t(:label_favorite),
                        classes: "op-primer--star-icon",
                        mr: 2
                      ))
             end

      link = render(Primer::Beta::Link.new(
                      href: project_resource_planner_path(project, model),
                      font_weight: :bold
                    )) { model.name }

      safe_join([icon, link].compact)
    end

    def work_packages
      # TODO: Implement a proper count
      "—"
    end

    def members
      # TODO: Implement a proper count
      "—"
    end

    def start_date
      helpers.format_date(model.start_date) if model.start_date.present?
    end

    def finish_date
      helpers.format_date(model.end_date) if model.end_date.present?
    end

    def button_links
      [action_menu]
    end

    def action_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal",
                              "aria-label": t(:label_more),
                              scheme: :invisible)

        edit_item(menu) if edit_allowed?
        favorite_item(menu)
        toggle_public_item(menu) if toggle_public_allowed?
        delete_item(menu) if delete_allowed?
      end
    end

    def edit_item(menu)
      menu.with_item(
        label: t("resource_management.action.edit"),
        tag: :a,
        href: edit_project_resource_planner_path(project, model),
        content_arguments: { data: { controller: "async-dialog" } }
      ) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def favorite_item(menu)
      favorited = model.favorited_by?(User.current)
      label = favorited ? t("resource_management.action.unfavorite") : t("resource_management.action.favorite")
      icon = favorited ? :star : :"star-fill"
      method = favorited ? :delete : :post

      menu.with_item(
        label:,
        href: favorite_path(object_type: "persisted_views", object_id: model.id),
        content_arguments: { data: { turbo_method: method } }
      ) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def toggle_public_item(menu)
      label = model.public? ? t("resource_management.action.make_private") : t("resource_management.action.make_public")
      icon = model.public? ? :lock : :globe

      menu.with_item(
        label:,
        href: toggle_public_project_resource_planner_path(project, model),
        content_arguments: { data: { turbo_method: :post } }
      ) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def delete_item(menu)
      menu.with_item(
        label: t("resource_management.action.delete"),
        scheme: :danger,
        href: project_resource_planner_path(project, model),
        content_arguments: {
          data: {
            turbo_method: :delete,
            turbo_confirm: t(:text_are_you_sure)
          }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def toggle_public_allowed?
      User.current.allowed_in_project?(:manage_public_resource_planners, project)
    end

    def edit_allowed?
      manage_allowed?
    end

    def delete_allowed?
      return true if User.current.active_admin?

      manage_allowed?
    end

    def manage_allowed?
      return false if project.nil?

      owns_planner = model.principal == User.current &&
        User.current.allowed_in_project?(:view_resource_planners, project)
      can_manage_public = model.public? &&
        User.current.allowed_in_project?(:manage_public_resource_planners, project)

      owns_planner || can_manage_public
    end
  end
end
