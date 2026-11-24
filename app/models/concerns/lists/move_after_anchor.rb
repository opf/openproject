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

module Lists
  # Anchor-based reordering for acts_as_list models: places the record
  # directly below another record of the same list, addressed by id.
  module MoveAfterAnchor
    # ActiveRecord casts "7junk", "07", " 7" and true alike to integers, so an
    # id has to be vetted before it reaches find_by, or it matches a record the
    # request never pointed at.
    def self.canonical_id(value)
      case value
      when Integer then value if value.positive?
      when /\A[1-9]\d*\z/ then value.to_i
      end
    end

    # The position a record takes when it enters `scope` below `prev_id`: 1 for
    # `nil` or an empty string, nil when `prev_id` is anything but a positive
    # Integer or its canonical decimal String, is unknown to `scope`, or is
    # this record itself.
    def position_after_anchor(prev_id, scope:)
      return 1 if prev_id.nil? || prev_id == ""

      anchor_id = MoveAfterAnchor.canonical_id(prev_id)
      return if anchor_id.nil? || anchor_id == id

      anchor = scope.find_by(id: anchor_id)
      anchor.position + 1 if anchor
    end

    # Moves this record, already a member of `scope`, below `prev_id`. Returns
    # false without mutating wherever #position_after_anchor returns nil.
    def move_after_anchor(prev_id, scope:)
      target = position_after_anchor(prev_id, scope:)
      return false if target.nil?

      # insert_at numbers the list with this record pulled out of it, so the
      # target slips up a slot whenever the record currently sits above it.
      insert_at(position < target ? target - 1 : target)
      true
    end
  end
end
