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
    def with_card_hash
      instance_version = connection.quote(OpenProject::VERSION.to_s)

      left_outer_joins(:status, :assigned_to, :type, :priority)
        .joins("LEFT JOIN work_packages card_hash_parents ON card_hash_parents.id = work_packages.parent_id")
        .select(WorkPackage.arel_table[Arel.star], Arel.sql(<<~SQL.squish))
          md5(concat_ws('/',
            #{instance_version},
            work_packages.updated_at,
            work_packages.lock_version,
            card_hash_parents.updated_at,
            statuses.updated_at,
            users.updated_at,
            types.updated_at,
            enumerations.updated_at
          )) AS card_hash
        SQL
    end
  end
end
