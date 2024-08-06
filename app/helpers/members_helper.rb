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

module MembersHelper
  # Adds a link that either:
  # * sends a delete request to memberships in case only one role is assigned to the member
  # * sends a patch request to memberships in case there is more than one role assigned to the member
  #
  # If it is the later, the ids of the non delete roles are appended to the url so that they are kept.
  def global_member_role_deletion_link(member, role)
    if member.roles.length == 1
      link_to("",
              principal_membership_path(member.principal, member),
              { method: :delete, class: "icon icon-delete", title: t(:button_delete) })
    else
      link_to("",
              principal_membership_path(member.principal, member, "membership[role_ids]" => member.roles - [role]),
              { method: :patch, class: "icon icon-delete", title: t(:button_delete) })
    end
  end

  ##
  # Decorate the form_for helper for membership of a user or a group to a global
  # role.
  def global_role_membership_form_for(principal, global_member, options = {}, &)
    args =
      if global_member
        { url: principal_membership_path(principal, global_member), method: :patch }
      else
        { url: principal_memberships_path(principal), method: :post }
      end

    form_for(:principal_roles, args.merge(options), &)
  end

  def principal_membership_path(principal, global_member, options = {})
    if principal.is_a?(Group)
      membership_of_group_path(principal, global_member, options)
    else
      user_membership_path(principal, global_member, options)
    end
  end

  def principal_memberships_path(principal, options = {})
    if principal.is_a?(Group)
      memberships_of_group_path(principal, options)
    else
      user_memberships_path(principal, options)
    end
  end
end
