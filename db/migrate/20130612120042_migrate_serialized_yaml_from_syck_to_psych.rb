#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'migration_utils/yaml_migrator'

class MigrateSerializedYamlFromSyckToPsych < ActiveRecord::Migration
  include Migration::YamlMigrator

  def up
    migrate_yaml_columns('syck', 'psych')
  end

  def down
    migrate_yaml_columns('psych', 'syck')
  end

  def migrate_yaml_columns(source_yamler, target_yamler)
    ['filters', 'column_names', 'sort_criteria'].each do |column|
      migrate_yaml('queries', column, source_yamler, target_yamler)
    end
    migrate_yaml('custom_field_translations', 'possible_values', source_yamler, target_yamler)
    migrate_yaml('roles', 'permissions', source_yamler, target_yamler)
    migrate_yaml('settings', 'value', source_yamler, target_yamler)
    migrate_yaml('timelines', 'options', source_yamler, target_yamler)
    migrate_yaml('user_preferences', 'others', source_yamler, target_yamler)
    migrate_yaml('wiki_menu_items', 'options', source_yamler, target_yamler)
  end

end
