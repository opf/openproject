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

require Rails.root.join("db/migrate/migration_utils/permission_renamer")
require Rails.root.join("db/migrate/migration_utils/permission_adder")

class MigrateBacklogsPermissions < ActiveRecord::Migration[8.1]
  def up
    ::Migration::MigrationUtils::PermissionRenamer.rename(:view_master_backlog, :view_sprints)
    ::Migration::MigrationUtils::PermissionRenamer.rename(:view_taskboards, :view_sprints)

    ::Migration::MigrationUtils::PermissionAdder.add(:manage_versions, :create_sprints)
    ::Migration::MigrationUtils::PermissionRenamer.rename(:update_sprints, :create_sprints)

    ::Migration::MigrationUtils::PermissionAdder.add(:assign_versions, :manage_sprint_items)
  end

  def down
    # Note: Ideally the `:view_taskboards`, `:view_master_backlog`, `:manage_versions`,
    # `:update_sprints` permissions should be restored too, but unfortunately we cannot know
    #  which one lead to the user gaining `:view_sprints` or `:create_sprints` permissions.
    # There are 2 possible solutions for this issue:
    #   1. Grant both the `:view_taskboards`, `:view_master_backlog` where `:view_sprints` was granted.
    #      Respectively, grant `:manage_versions`, `:update_sprints` permissions where `:create_sprints`
    #      was granted. Unfortunately this leads to users gaining permissions they didn't possibly had
    #      before the migration.
    #   2. Grant none of the undecisible permissions, which leads to users losing permissions they had
    #      before the migration.
    #
    # The conservative approach here is to pick #2, because it avoids accidentally leaking permissions
    # to users.

    # Remove new permissions that were added during the up migration
    RolePermission.delete_by(permission: %w(view_sprints create_sprints manage_sprint_items))
  end
end
