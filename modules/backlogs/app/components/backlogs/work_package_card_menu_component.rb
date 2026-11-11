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

module Backlogs
  # Renders Primer::Alpha::ActionMenu::List for the deferred menu (Backlogs::WorkPackagesController#menu).
  # +menu_id+ must match the row ActionMenu in WorkPackageCardComponent.
  class WorkPackageCardMenuComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include CommonHelper
    include SortableLists::MoveMenu

    attr_reader :invoker, :work_packages, :destinations, :project, :current_user, :stale_scope

    # A scope of several cards gets a batch menu of move actions only. When
    # none applies, the batch menu says so.
    #
    # @param invoker [WorkPackage] the card the menu opened on; it names the
    #   menu and carries its singular actions.
    # @param work_packages [Array<WorkPackage>] the ordered selection the
    #   destination actions apply to, including the invoker.
    # @param destinations [Backlogs::WorkPackages::DestinationAvailability]
    #   the destinations every member of `work_packages` may move to.
    def initialize(project:, invoker:, work_packages:, destinations:, current_user: User.current, stale_scope: false)
      super()

      @project = project
      @invoker = invoker
      @work_packages = work_packages
      @destinations = destinations
      @current_user = current_user
      @stale_scope = stale_scope
    end

    def menu_id
      dom_target(invoker, :menu)
    end

    private

    def list_data
      {
        sortable_lists__menu_source_target: "menu",
        sortable_lists_scope_count: batch_menu? ? work_packages.size : 1,
        sortable_lists_scope_ids: (batch_menu? ? work_packages : [invoker]).map { |wp| wp.id.to_s }.to_json
      }
    end

    def batch_menu?
      !stale_scope && work_packages.many?
    end

    def show_no_batch_actions?
      batch_menu? && !moves_locked? && !any_destination?
    end

    # The client hides Move to position for a block that cannot move in any
    # direction, which only the DOM can tell. When it is the sole batch
    # action, the explanation rides along hidden for the client to reveal.
    def no_batch_actions_item_arguments
      return {} unless show_move_items?

      { hidden: true, data: { sortable_lists__item_target: "moveUnavailable" } }
    end

    # Above the cap the batch menu still renders, with its actions disabled
    # and the reason given once.
    def moves_locked?
      work_packages.size > Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE
    end

    def batch_too_large_message
      t("js.backlogs.announcements.batch_too_large",
        count: work_packages.size,
        max: Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE)
    end

    def destination_item_arguments(key, **wiring)
      {
        id: dom_target(invoker, :menu, key),
        label: t(".action_menu.#{key}"),
        tag: :button,
        **(moves_locked? ? { disabled: true } : wiring)
      }
    end

    # Positional moves reorder within the cards' own list, which the server
    # allows even for a read-only work package, so they gate on the page-level
    # permission and on every member sharing one list, not on whether any
    # cross-container destination is offered.
    def show_move_items?
      destinations.manage_permission? && one_list?
    end

    def one_list?
      work_packages.map { |work_package| Backlogs::Target.for_work_package(work_package) }.uniq.one?
    end

    def show_move_to_inbox?
      destinations.inbox?
    end

    def show_move_to_backlog_bucket?
      destinations.buckets.any?
    end

    def show_move_to_sprint?
      destinations.sprints.any?
    end

    def id_inputs
      work_packages.map { |work_package| { name: "ids[]", value: work_package.id } }
    end

    def any_move_action?
      !stale_scope && (show_move_items? || any_destination?)
    end

    def any_destination?
      show_move_to_sprint? || show_move_to_inbox? || show_move_to_backlog_bucket?
    end

    def inbox_list_type
      Backlogs::Target::InboxId.list_type
    end
  end
end
