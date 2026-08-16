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
    include Concerns::WorkPackageMovability

    attr_reader :work_package, :project, :sprint_ids, :bucket_ids, :current_user

    def initialize(work_package:, project:, sprint_ids:, bucket_ids:, current_user: User.current)
      super()

      @work_package = work_package
      @project = project
      @sprint_ids = sprint_ids
      @bucket_ids = bucket_ids
      @current_user = current_user
    end

    def menu_id
      dom_target(work_package, :menu)
    end

    private

    # Positional moves reorder within the card's own list, which the server
    # allows even for a read-only work package, so they gate on the page-level
    # permission alone. Only the cross-container moves below require movable?.
    def show_move_items?
      sortable?
    end

    def show_move_to_inbox?
      sortable?
    end

    def show_move_to_backlog_bucket?
      sortable? && bucket_ids.any?
    end

    def show_move_to_sprint?
      sortable? && sprint_ids.any?
    end

    def show_move_submenu?
      show_move_items? || show_move_to_sprint? || show_move_to_inbox? || show_move_to_backlog_bucket?
    end

    def build_move_menu(menu)
      build_move_item(menu, label: :label_sort_highest, direction: "top", icon: :"move-to-top")
      build_move_item(menu, label: :label_sort_higher, direction: "up", icon: :"chevron-up")
      build_move_item(menu, label: :label_sort_lower, direction: "down", icon: :"chevron-down")
      build_move_item(menu, label: :label_sort_lowest, direction: "bottom", icon: :"move-to-bottom")
    end

    def build_move_item(menu, label:, icon:, direction:)
      # The `data:` hash must live on the item level so Primer renders it on
      # the ActionList `<li>`: the controller's `<li>` targets and the
      # action-menu API's `disableItem`/`enableItem` both address that element,
      # and the click action rides it via the bubbled button click.
      menu.with_item(
        id: dom_target(work_package, :menu, label),
        label: I18n.t(label),
        tag: :button,
        data: {
          sortable_lists__item_target: "moveItem",
          sortable_lists__item_direction_param: direction,
          action: "click->sortable-lists--item#move"
        }
      ) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def inbox_list_type
      Backlogs::Target::InboxId.list_type
    end

    def sprint_list_type
      Backlogs::Target::SprintId[nil].list_type
    end

    def bucket_list_type
      Backlogs::Target::BucketId[nil].list_type
    end

    def destination_data(type, ids)
      candidates = ids.map { |id| { type:, id: id.to_s } }
      candidates = [{ type:, id: nil }] if type == Backlogs::Target::InboxId.list_type

      {
        sortable_lists__item_target: "destinationItem",
        sortable_lists_destinations: candidates.to_json
      }
    end
  end
end
