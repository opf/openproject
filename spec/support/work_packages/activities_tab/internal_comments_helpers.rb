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
require "spec_helper"

module InternalCommentsHelpers
  def create_user_without_internal_comments_view_permissions
    viewer_role = create(:project_role, permissions: %i[view_work_packages])
    create(:user,
           firstname: "A",
           lastname: "Viewer",
           member_with_roles: { project => viewer_role })
  end

  def create_user_as_project_admin
    member_role = create(:project_role,
                         permissions: %i[view_work_packages add_work_package_comments
                                         edit_own_work_package_comments
                                         view_internal_comments
                                         add_internal_comments
                                         edit_own_internal_comments
                                         edit_others_internal_comments])
    create(:user, firstname: "Project", lastname: "Admin",
                  member_with_roles: { project => member_role })
  end

  def create_user_with_internal_comments_view_permissions
    viewer_role = create(:project_role, permissions: %i[view_work_packages view_internal_comments])
    create(:user,
           firstname: "Internal",
           lastname: "Viewer",
           member_with_roles: { project => viewer_role })
  end

  def create_user_with_internal_comments_view_and_write_permissions
    viewer_role_with_commenting_permission = create(:project_role,
                                                    permissions: %i[view_work_packages add_work_package_comments
                                                                    edit_own_work_package_comments
                                                                    view_internal_comments
                                                                    add_internal_comments
                                                                    edit_own_internal_comments])
    create(:user,
           firstname: "Internal",
           lastname: "ViewerCommenter",
           member_with_roles: { project => viewer_role_with_commenting_permission })
  end
end
