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

module ResourcePlannerViews
  module Timeline
    # Shared toolbar for the resource-timeline sub-headers. FullCalendar runs
    # headless (`headerToolbar: false`), so these controls drive it from outside
    # via the shared Stimulus controller. The whole toolbar is built here from
    # the shared `resource_management.timeline` translations; including
    # components supply only their entity-specific add entry (`add_entity_item`).
    module SubHeader
      extend ActiveSupport::Concern

      # Builds the full toolbar into the given Primer SubHeader builder.
      def render_timeline_actions(subheader)
        render_navigation_actions(subheader)
        render_granularity_action(subheader)
        render_settings_action(subheader)
        render_add_actions(subheader)
      end

      private

      def render_navigation_actions(subheader)
        subheader.with_action_button(tag: :button, leading_icon: :calendar,
                                     label: t("resource_management.timeline.navigation.today"),
                                     data: nav_action("today")) { t("resource_management.timeline.navigation.today") }
        subheader.with_action_button(icon_only: true, leading_icon: :"chevron-left", tag: :button,
                                     label: t("resource_management.timeline.navigation.previous"), data: nav_action("prev"))
        subheader.with_action_button(icon_only: true, leading_icon: :"chevron-right", tag: :button,
                                     label: t("resource_management.timeline.navigation.next"), data: nav_action("next"))
      end

      def render_granularity_action(subheader)
        subheader.with_action_menu(
          leading_icon: :clock,
          trailing_icon: :"triangle-down",
          label: granularity_label(default_granularity_key),
          button_arguments: { "aria-label": granularity_label(default_granularity_key), data: granularity_button_data }
        ) do |menu|
          granularities.each do |key, view_name|
            menu.with_item(label: granularity_label(key), tag: :button,
                           content_arguments: { data: granularity_action(key, view_name) }) { granularity_label(key) }
          end
        end
      end

      def render_settings_action(subheader)
        subheader.with_action_button(
          icon_only: true,
          leading_icon: :gear,
          label: t("resource_management.timeline.subheader.settings"),
          tag: :a,
          href: edit_project_resource_planner_view_path(@project, @resource_planner, @view),
          data: { controller: "async-dialog" }
        )
      end

      def render_add_actions(subheader)
        if @view.manually_picked?
          render_add_menu(subheader)
        elsif allowed_to_allocate?
          render_allocate_button(subheader)
        end
      end

      def render_add_menu(subheader)
        subheader.with_action_menu(
          leading_icon: :plus,
          trailing_icon: :"triangle-down",
          label: t("resource_management.timeline.subheader.add"),
          anchor_align: :end,
          button_arguments: { scheme: :primary, "aria-label": t("resource_management.timeline.subheader.add") }
        ) do |menu|
          render_allocate_item(menu) if allowed_to_allocate?
          add_entity_item(menu)
        end
      end

      def render_allocate_item(menu)
        menu.with_item(label: t("resource_management.timeline.subheader.allocate"), tag: :a,
                       href: new_project_resource_allocation_path(@project, resource_planner_view_id: @view.id),
                       content_arguments: { data: { controller: "async-dialog" } }) do |item|
          item.with_leading_visual_icon(icon: :people)
        end
      end

      def render_allocate_button(subheader)
        label = t("resource_management.timeline.subheader.allocate")
        subheader.with_action_button(leading_icon: :plus, scheme: :primary, tag: :a, label:,
                                     href: new_project_resource_allocation_path(@project, resource_planner_view_id: @view.id),
                                     data: { controller: "async-dialog" }) { label }
      end

      # The view-specific "add work package" / "add user" menu entry.
      def add_entity_item(_menu)
        raise SubclassResponsibilityError
      end

      def granularities
        Granularity::VIEWS
      end

      def default_granularity_key
        Granularity::DEFAULT
      end

      # The Stimulus controller is owned by the content component, which mounts it.
      def nav_action(method)
        { action: "#{Content::STIMULUS}##{method}" }
      end

      def granularity_action(key, view_name)
        { action: "#{Content::STIMULUS}#setView",
          "#{Content::STIMULUS}-view-param": view_name,
          "#{Content::STIMULUS}-label-param": granularity_label(key) }
      end

      # Target the controller uses to update the button label on granularity change.
      def granularity_button_data
        { "#{Content::STIMULUS}-target": "granularityButton" }
      end

      def granularity_label(key)
        t("resource_management.timeline.granularity.#{key}")
      end

      def allowed_to_allocate?
        User.current.allowed_in_project?(:allocate_user_resources, @project)
      end
    end
  end
end
