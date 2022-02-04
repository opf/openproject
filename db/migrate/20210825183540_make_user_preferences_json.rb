require_relative './migration_utils/utils'

class MakeUserPreferencesJson < ActiveRecord::Migration[6.1]
  include ::Migration::Utils

  class UserPreferenceWithOthers < ::UserPreference
    self.table_name = 'user_preferences'
    serialize :others, Hash
    serialize :settings, ::Serializers::IndifferentHashSerializer
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
