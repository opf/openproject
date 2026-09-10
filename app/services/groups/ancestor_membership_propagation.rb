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

module Groups
  module AncestorMembershipPropagation
    extend ActiveSupport::Concern

    private

    # Inherited memberships are materialized as member_roles pointing back at the ancestor's
    # member_role, so they have to be (re)created whenever a group's set of ancestors changes.
    # Both the groups in the subtree and their users receive them.
    def propagate_ancestor_memberships(group)
      subtree = group.self_and_descendants.to_a
      principal_ids = (subtree.flat_map(&:user_ids) + subtree.map(&:id)).uniq

      group.ancestors.each do |ancestor|
        Groups::CreateInheritedRolesService
          .new(ancestor, current_user: user)
          .call(user_ids: principal_ids)
      end
    end
  end
end
