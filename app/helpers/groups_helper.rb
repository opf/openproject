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

module GroupsHelper
  def group_settings_tabs(group)
    [
      {
        name: "general",
        partial: "groups/general",
        path: edit_group_path(group),
        label: :label_general
      },
      {
        name: "users",
        partial: "groups/users",
        path: edit_group_path(group, tab: :users),
        label: :label_user_plural
      },
      {
        name: "memberships",
        partial: "groups/memberships",
        path: edit_group_path(group, tab: :memberships),
        label: :label_project_plural
      },
      {
        name: "global_roles",
        partial: "principals/global_roles",
        path: edit_group_path(group, tab: :global_roles),
        label: :label_global_roles
      }
    ]
  end

  def autocompleter_filters(group)
    [
      { name: "status", operator: "=", values: ["active", "invited"] },
      { name: "group", operator: "!", values: [group.id] }
    ]
  end
end
