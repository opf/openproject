#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class NormalizePermissions < ActiveRecord::Migration[5.0]
  class Role < ActiveRecord::Base
    self.table_name = :roles

    self.inheritance_column = :_type_disabled

    serialize :permissions, Array
  end

  class RolePermission < ActiveRecord::Base
    self.table_name = :role_permissions
  end

  def up
    create_table :role_permissions do |p|
      p.string :permission
      p.integer :role_id

      p.index :role_id

      p.timestamps
    end

    NormalizePermissions::Role.all.each do |role|
      role.permissions.each do |p|
        NormalizePermissions::RolePermission.create(role_id: role.id, permission: p)
      end
    end

    remove_column :roles, :permissions
  end

  def down
    add_column :roles, :permissions, :text

    NormalizePermissions::RolePermission.all.to_a.group_by(&:role_id).each do |role_id, permissions|
      Role.where(id: role_id).update_all(permissions: permissions.map(&:permission))
    end

    drop_table :role_permissions
  end
end
