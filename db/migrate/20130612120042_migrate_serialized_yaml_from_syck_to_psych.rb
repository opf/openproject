#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

require_relative 'migration_utils/legacy_yamler'

class MigrateSerializedYamlFromSyckToPsych < ActiveRecord::Migration
  include Migration::LegacyYamler

  def up
    %w(filters column_names sort_criteria).each do |column|
      migrate_to_psych('queries', column)
    end

    migrate_to_psych('custom_field_translations', 'possible_values')
    migrate_to_psych('roles', 'permissions')
    migrate_to_psych('settings', 'value')
    migrate_to_psych('timelines', 'options')
    migrate_to_psych('user_preferences', 'others')
    migrate_to_psych('wiki_menu_items', 'options')
  end

  def down
    puts 'YAML data serialized with Psych is still compatible with Syck. Skipping migration.'
  end
end
