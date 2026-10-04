# frozen_string_literal: true

#
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
require Rails.root.join("db/migrate/migration_utils/permission_renamer")

class RenameCommentPermissions < ActiveRecord::Migration[8.0]
  def up
    ::Migration::MigrationUtils::PermissionRenamer.rename("add_work_package_notes", "add_work_package_comments")
    ::Migration::MigrationUtils::PermissionRenamer.rename("edit_own_work_package_notes", "edit_own_work_package_comments")
    ::Migration::MigrationUtils::PermissionRenamer.rename("edit_work_package_notes", "edit_work_package_comments")

    ::Migration::MigrationUtils::PermissionRenamer.rename("view_comments_with_restricted_visibility", "view_internal_comments")
    ::Migration::MigrationUtils::PermissionRenamer.rename("add_comments_with_restricted_visibility", "add_internal_comments")
    ::Migration::MigrationUtils::PermissionRenamer.rename("edit_own_comments_with_restricted_visibility",
                                                          "edit_own_internal_comments")
    ::Migration::MigrationUtils::PermissionRenamer.rename("edit_others_comments_with_restricted_visibility",
                                                          "edit_others_internal_comments")
  end

  def down
    ::Migration::MigrationUtils::PermissionRenamer.rename("add_work_package_comments", "add_work_package_notes")
    ::Migration::MigrationUtils::PermissionRenamer.rename("edit_own_work_package_comments", "edit_own_work_package_notes")
    ::Migration::MigrationUtils::PermissionRenamer.rename("edit_work_package_comments", "edit_work_package_notes")

    ::Migration::MigrationUtils::PermissionRenamer.rename("view_internal_comments", "view_comments_with_restricted_visibility")
    ::Migration::MigrationUtils::PermissionRenamer.rename("add_internal_comments", "add_comments_with_restricted_visibility")
    ::Migration::MigrationUtils::PermissionRenamer.rename("edit_own_internal_comments",
                                                          "edit_own_comments_with_restricted_visibility")
    ::Migration::MigrationUtils::PermissionRenamer.rename("edit_others_internal_comments",
                                                          "edit_others_comments_with_restricted_visibility")
  end
end
