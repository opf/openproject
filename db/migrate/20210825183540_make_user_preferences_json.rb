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

require_relative "migration_utils/utils"

class MakeUserPreferencesJson < ActiveRecord::Migration[6.1]
  include ::Migration::Utils

  class UserPreferenceWithOthers < ::UserPreference
    self.table_name = "user_preferences"
    serialize :others, type: Hash
    serialize :settings, coder: ::Serializers::IndifferentHashSerializer
  end

  def up
    add_column :user_preferences, :settings, :jsonb, default: {}

    UserPreferenceWithOthers.reset_column_information
    in_configurable_batches(UserPreferenceWithOthers).each_record do |pref|
      migrate_yaml_to_json(pref)
      pref.save!(validate: false)
    end

    change_table :user_preferences, bulk: true do |t|
      t.remove :others, :hide_mail, :time_zone
    end
  end

  def down
    change_table :user_preferences, bulk: true do |t|
      t.text :others
      t.boolean :hide_mail, default: true
      t.text :time_zone
    end

    UserPreferenceWithOthers.reset_column_information
    in_configurable_batches(UserPreferenceWithOthers).each_record do |pref|
      migrate_json_to_yaml(pref)
      pref.save!(validate: false)
    end

    remove_column :user_preferences, :settings, :jsonb
  end

  private

  def migrate_yaml_to_json(pref)
    pref.settings = pref.others
    pref.settings[:hide_mail] = pref.hide_mail
    pref.settings[:time_zone] = pref.time_zone
  end

  def migrate_json_to_yaml(pref)
    pref.others = pref.settings
    pref.hide_mail = pref.settings[:hide_mail]
    pref.time_zone = pref.settings[:time_zone]
  end
end
