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
  class WorkPackageCardListItemComponent < OpenProject::Common::BorderBoxListComponent::WorkPackageItem
    include CommonHelper
    include Concerns::WorkPackageMovability

    private

    def build_card
      WorkPackageCardComponent.new(
        work_package:,
        menu_src:,
        **card_arguments
      )
    end

    # Every sortable card drags: a read-only one stays a drag source too, only
    # confined to its own list (see {#mobility}).
    def draggable?
      sortable?
    end

    def split_url
      url_helpers.project_backlogs_backlog_details_path(project, work_package, params)
    end

    def full_url
      url_helpers.work_package_path(work_package)
    end

    def menu_src
      url_helpers.menu_project_backlogs_work_package_path(project, work_package)
    end

    # @return [Hash] card arguments carrying the Backlogs-only keyboard wiring.
    #   `tabindex` lives here rather than in the base because only this subclass
    #   attaches the `backlogs--work-package` Enter handler; a focusable base card
    #   would be a dead tab stop. The `:has(> .Box-card:focus-visible)` row rule
    #   depends on this focusability.
    def card_arguments
      arguments = super
      arguments[:tabindex] = 0
      arguments[:data] = merge_data(arguments, { data: card_data })
      arguments[:aria] = merge_aria(arguments, { aria: card_aria })
      arguments
    end

    def card_data
      {
        story: true,
        # Non-movable cards opt in too: they have no move actions, but their
        # singular menu is still worth reaching contextually.
        controller: "backlogs--work-package contextual-action-menu",
        backlogs__work_package_id_value: work_package.id,
        backlogs__work_package_display_id_value: work_package.display_id,
        backlogs__work_package_split_url_value: split_url,
        backlogs__work_package_full_url_value: full_url,
        # The card, not the row, carries the tab stop.
        sortable_lists__item_target: "preview handle focus"
      }
    end

    # @return [Hash] ARIA wiring announcing the card's Enter activation and its
    #   context-menu shortcut without claiming button or draggable semantics.
    #   Shift+F10 is the conventional context-menu command in the WAI-ARIA APG
    #   and is worth announcing; the dedicated Context Menu key is left out
    #   because it needs no discovery — pressing it is its own affordance.
    def card_aria
      {
        keyshortcuts: "Enter Shift+F10",
        label: work_package.to_fs(:caption)
      }
    end

    # Every card row is a sortable item, movable or not: a non-movable row is
    # still an addressable position its neighbours anchor drops on.
    def row_data
      {
        controller: "sortable-lists--item",
        sortable_lists__item_id_value: work_package.id,
        sortable_lists__item_label_value: work_package.to_fs(:caption),
        sortable_lists__item_type_value: "work_package",
        sortable_lists__item_mobility_value: mobility,
        sortable_lists__item_batch_menu_label_key_value: "js.backlogs.action_menu.batch_menu_label",
        # The same string the card menu's invoker tooltip renders; the
        # controller restores it from here rather than trusting the tooltip
        # text, which a Turbo snapshot can capture mid-rename.
        sortable_lists__item_singular_menu_label_value:
          I18n.t(:"open_project.common.work_package_card_component.menu.label_actions"),
        # Native drag payload for external consumers; the same absolute URL
        # as the card menu's "Copy URL to clipboard" item. The label above
        # doubles as the link text of the text/html flavour.
        sortable_lists__item_external_url_value: url_helpers.work_package_url(work_package)
      }
    end

    public

    def row_args
      arguments = super
      arguments[:draggable] = true if draggable?
      arguments
    end
  end
end
