#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

module MembersHelper
  # Adds a link that either:
  # * sends a delete request to memberships in case only one role is assigned to the member
  # * sends a patch request to memberships in case there is more than one role assigned to the member
  #
  # If it is the later, the ids of the non delete roles are appended to the url so that they are kept.
  def global_member_role_deletion_link(member, role)
    if member.roles.length == 1
      path =
        if member.principal.is_a?(Group)
          membership_of_group_path(member.principal, member)
        else
          user_membership_path(user_id: member.user_id, id: member.id)
        end

      link_to('',
              path,
              { method: :delete, class: 'icon icon-delete', title: t(:button_delete) })
    else
      path =
        if member.principal.is_a?(Group)
          membership_of_group_path(member.principal, member, 'membership[role_ids]' => member.roles - [role])
        else
          user_membership_path(user_id: member.user_id, id: member.id, 'membership[role_ids]' => member.roles - [role])
        end

      link_to('',
              path,
              { method: :patch, class: 'icon icon-delete', title: t(:button_delete) })
    end
  end
end
