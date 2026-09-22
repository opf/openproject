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

module Backlogs::Concerns
  # Decides whether a card may offer to move its work package.
  #
  # The card row and the card menu are separate components that each render a
  # way to move it, so the decision lives here and both consume it: a
  # surface that answered the question for itself would be free to drift out of
  # step with the other, which is the defect this exists to prevent.
  #
  # Requires `work_package`, `project` and `current_user` in the including
  # component; `project` and `current_user` are what {#sortable?} resolves the
  # permission against.
  module WorkPackageMovability
    include Backlogs::CommonHelper

    private

    # Whether the card takes part in its list's ordering at all. This is the
    # page-level factor: `manage_sprint_items` resolves against the page's
    # project, so it answers the same way for every card on the page.
    #
    # @return [Boolean] whether the card belongs to the list's ordering model.
    def sortable?
      user_allowed?(:manage_sprint_items)
    end

    # Whether this particular work package may leave its container. A read-only
    # status blocks every attribute write
    # ({WorkPackages::BaseContract#readonly_attributes_unchanged}), and a move
    # to another sprint, backlog bucket or the inbox writes `sprint_id` or
    # `backlog_bucket_id`, so the server refuses it no matter which surface
    # asked. A reorder within the card's own list writes no attribute at all —
    # position is applied by `move_after` once the contract has passed — so it
    # stays allowed and keeps gating on {#sortable?} alone.
    #
    # A card can be sortable without being movable, and that distinction
    # matters: an unmovable card is frozen in its container, not in its order.
    # It keeps its drag (confined to its own list) and its positional move
    # actions; only the cross-container moves go.
    #
    # Read-only statuses are an Enterprise feature ({Status.can_readonly?}), so
    # in Community this reduces to {#sortable?}.
    #
    # @return [Boolean] whether a move to another container may be offered for
    #   this work package.
    def movable?
      sortable? && !work_package.readonly_status?
    end

    # What ordering this card takes part in.
    #
    # `fixed` is no part at all: no drag, no positional move, no selection.
    # `confined` reorders within its own list but is refused by every other
    # container. `free` may move to any list that accepts it.
    #
    # @return [String] one of "fixed", "confined", "free".
    def mobility
      return "fixed" unless sortable?

      movable? ? "free" : "confined"
    end
  end
end
