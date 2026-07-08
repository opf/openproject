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

module Backlogs
  # Renders Primer::Alpha::ActionMenu::List for the deferred menu (Backlogs::WorkPackagesController#menu).
  # +menu_id+ must match the row ActionMenu in WorkPackageCardComponent.
  class WorkPackageCardMenuComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include CommonHelper

    attr_reader :work_package, :project, :open_sprints_exist, :other_buckets_exist, :current_user

    def initialize(work_package:, project:, open_sprints_exist:, other_buckets_exist:, current_user: User.current)
      super()

      @work_package = work_package
      @project = project
      @open_sprints_exist = open_sprints_exist
      @other_buckets_exist = other_buckets_exist
      @current_user = current_user
    end

    def menu_id
      dom_target(work_package, :menu)
    end

    private

    def show_move_items?
      allowed_to_manage_sprint_items?
    end

    def show_move_to_inbox?
      allowed_to_manage_sprint_items? && (work_package.sprint_id? || work_package.backlog_bucket_id?)
    end

    def show_move_to_backlog_bucket?
      allowed_to_manage_sprint_items? && other_buckets_exist
    end

    def show_move_to_sprint?
      allowed_to_manage_sprint_items? && open_sprints_exist
    end

    def show_move_submenu?
      show_move_items? || show_move_to_sprint? || show_move_to_inbox? || show_move_to_backlog_bucket?
    end

    def allowed_to_manage_sprint_items?
      user_allowed?(:manage_sprint_items)
    end

    def build_move_menu(menu)
      build_move_item(menu, label: :label_sort_highest, direction: "top", icon: :"move-to-top")
      build_move_item(menu, label: :label_sort_higher, direction: "up", icon: :"chevron-up")
      build_move_item(menu, label: :label_sort_lower, direction: "down", icon: :"chevron-down")
      build_move_item(menu, label: :label_sort_lowest, direction: "bottom", icon: :"move-to-bottom")
    end

    def build_move_item(menu, label:, icon:, direction:)
      # Item-level `data:` renders on the ActionList `<li>` (verify against
      # Primer::Alpha::ActionList::Item) so the controller's `<li>` targets and
      # the API's `disableItem`/`enableItem` land on the right element; the click
      # action rides the same `<li>` and fires on the bubbled button click.
      menu.with_item(
        id: dom_target(work_package, :menu, label),
        label: I18n.t(label),
        tag: :button,
        data: {
          sortable_lists__item_target: "moveItem",
          move_direction: direction,
          action: "click->sortable-lists--item#move"
        }
      ) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def inbox_list_type
      Backlogs::Target::InboxId.list_type
    end
  end
end
