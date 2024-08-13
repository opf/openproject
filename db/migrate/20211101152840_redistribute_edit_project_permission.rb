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

class RedistributeEditProjectPermission < ActiveRecord::Migration[6.1]
  def up
    add_permission("select_custom_fields")
    add_permission("select_done_status")
  end

  def down
    remove_permission("select_custom_fields")
    remove_permission("select_done_status")
  end

  private

  def add_permission(name)
    execute <<~SQL.squish
      INSERT INTO
      role_permissions
      (permission, role_id, created_at, updated_at)
      SELECT '#{name}', role_id, NOW(), NOW()
      FROM role_permissions
      WHERE permission = 'edit_project'
    SQL
  end

  def remove_permission(name)
    execute <<~SQL.squish
      DELETE FROM
      role_permissions
      WHERE permission = '#{name}'
    SQL
  end
end
