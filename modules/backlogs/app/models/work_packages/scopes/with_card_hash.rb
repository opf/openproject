# frozen_string_literal: true

# -- copyright
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
# ++

# Adds a +card_hash+ projection to the selected work packages.
#
# The hash fingerprints everything a backlogs work package card displays: the
# work package itself (subject, story points and all foreign keys touch
# +work_packages.updated_at+) as well as the records rendered alongside it
# (parent, status, assignee, type and priority). Including the related records'
# +updated_at+ catches edits to those records (e.g. a renamed status) that do
# not touch the work package itself.
#
# The parent contributes its +updated_at+ only while it is visible to the user,
# matching the card which shows the parent's subject only then. This makes the
# hash user-specific and busts the cache when the parent's visibility toggles.
#
# The current OpenProject version is mixed in so that every card is busted when
# the instance is updated, covering changes to the card markup itself between
# releases.
#
# The hash is used as the cache-busting +version+ of the card's lazily loaded
# turbo-frame: as long as the hash is stable the client keeps the cached card,
# and a changed hash points the frame at a fresh URL.
module WorkPackages::Scopes::WithCardHash
  extend ActiveSupport::Concern

  class_methods do
    def with_card_hash(user = User.current)
      instance_version = connection.quote(OpenProject::VERSION.to_s)

      left_outer_joins(:status, :assigned_to, :type, :priority)
        .joins("LEFT JOIN work_packages card_hash_parents ON card_hash_parents.id = work_packages.parent_id")
        .select(WorkPackage.arel_table[Arel.star], Arel.sql(<<~SQL.squish))
          md5(concat_ws('/',
            #{instance_version},
            work_packages.updated_at,
            work_packages.lock_version,
            #{visible_parent_updated_at(user)},
            statuses.updated_at,
            users.updated_at,
            types.updated_at,
            enumerations.updated_at
          )) AS card_hash
        SQL
    end

    private

    # The card shows the parent's subject only while the parent is visible to
    # the user, and an "undisclosed" placeholder otherwise. The parent therefore
    # contributes its updated_at while visible and nothing otherwise (whether it
    # is hidden or absent). Adding or removing a parent already bumps
    # work_packages.updated_at, so only the visible/hidden toggle needs tracking
    # here.
    def visible_parent_updated_at(user)
      # Built unscoped so the surrounding relation (e.g. the backlog filters or
      # the id of the work package being loaded) does not leak into the
      # visibility subquery, which must be free to match the parent row.
      visible_parent = unscoped do
        WorkPackage
          .visible(user)
          .where("work_packages.id = card_hash_parents.id")
          .select("1")
          .to_sql
      end

      "CASE WHEN EXISTS (#{visible_parent}) THEN card_hash_parents.updated_at END"
    end
  end
end
