# frozen_string_literal: true

class RemoveVersionSettings < ActiveRecord::Migration[8.1]
  def up
    drop_table :version_settings
  end

  def down
    require_relative "tables/version_settings"

    Tables::VersionSettings.table(self)
  end
end
