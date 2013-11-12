#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2011-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require Rails.root.join("db","migrate","migration_utils","yaml_migrator").to_s

class MyProjectPageMigrateSerializedYaml < ActiveRecord::Migration
  include Migration::YamlMigrator

  def up
    ['top', 'left', 'right', 'hidden'].each do |column|
      migrate_yaml('my_projects_overviews', column, 'syck', 'psych')
    end
  end

  def down
    ['top', 'left', 'right', 'hidden'].each do |column|
      migrate_yaml('my_projects_overviews', column, 'psych', 'syck')
    end
  end
end
