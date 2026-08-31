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

module Lists
  # Anchor-based reordering for acts_as_list models: moves the record
  # directly below another record of the same list, addressed by id.
  module MoveAfterAnchor
    # Moves the record below the record identified by `prev_id` within
    # `scope` (a relation over the same acts_as_list list). A blank
    # `prev_id` moves the record to the top.
    #
    # Returns false without mutating when the anchor is unknown, outside
    # the scope, or the record itself.
    def move_after_anchor(prev_id, scope:) # rubocop:disable Naming/PredicateMethod -- verb command, not a query
      if prev_id.blank?
        move_to_top
        return true
      end

      anchor = scope.find_by(id: prev_id)
      return false if anchor.nil? || anchor.id == id

      # Removing the record first shifts the anchor up by one when the
      # record currently sits above it, so the target slot differs by
      # direction of travel.
      insert_at(position > anchor.position ? anchor.position + 1 : anchor.position)
      true
    end
  end
end
