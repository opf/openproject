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

class AssignableToPermission < ActiveRecord::Migration[6.1]
  def up
    # Because of a missing dependent: :destroy, some role_permission
    # for removed roles exist.
    execute <<~SQL.squish
      DELETE FROM role_permissions WHERE role_id IS NULL
    SQL

    execute <<~SQL.squish
      INSERT INTO role_permissions (role_id, permission, created_at, updated_at)
      SELECT id role_id, 'work_package_assigned' permission, NOW() created_at, NOW() updated_at FROM roles
      WHERE assignable AND type = 'Role' AND builtin = 0
    SQL

    remove_column :roles, :assignable
  end

  def down
    add_column :roles, :assignable, :boolean, default: true

    execute <<~SQL.squish
      UPDATE roles
      SET assignable = EXISTS(SELECT 1 from role_permissions WHERE permission = 'work_package_assigned' and role_id = roles.id)
    SQL

    execute <<~SQL.squish
      DELETE FROM role_permissions where permission = 'work_package_assigned'
    SQL
  end
end
