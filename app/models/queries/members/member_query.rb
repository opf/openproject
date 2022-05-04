#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

class Queries::Members::MemberQuery < Queries::BaseQuery
  def self.model
    Member
  end

  # Convert the Query into an ActiveRecord Relation
  def results
    # An invalid query reaults in an empty scope
    if !valid?
      return empty_scope
    end

    # Apply filters around a "select * from membership", but
    # don't yet apply_orders, because the DISTINCT (below...) will break order
    base_query = apply_filters(default_scope)

    # Add a "select distinct * from (...) members" around the Members base_query,
    # because users may appear multiple times if member of multiple groups (bug #38672).
    # Then also load roles and preference for speed-up.
    # This query is used in the /projects/<id>/member page and the also in the
    # membership_api, but there only to find the me
    distinct_query = self.class.model
        .from(base_query.distinct, :members)

    # Return the ordered query with additional resources eagerly loaded
    apply_orders(distinct_query)
      .includes(:roles, { principal: :preference }, :member_roles)
  end

  def default_scope
    Member.visible(User.current)
  end
end
