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

require "spec_helper"
require Rails.root.join("db/migrate/migration_utils/setting_renamer.rb")

RSpec.describe Migration::MigrationUtils::SettingRenamer, type: :model do # rubocop:disable RSpec/SpecFilePathFormat
  def insert_setting(name, value)
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array(
        ["INSERT INTO settings (name, value) VALUES (?, ?)", name, value]
      )
    )
  end

  def setting_value(name)
    ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql_array(
        ["SELECT value FROM settings WHERE name = ?", name]
      )
    )
  end

  def setting_exists?(name)
    ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql_array(
        ["SELECT EXISTS(SELECT 1 FROM settings WHERE name = ?)", name]
      )
    )
  end

  describe ".rename" do
    before { insert_setting("old_setting", "some_value") }

    it "renames the setting" do
      described_class.rename("old_setting", "new_setting")

      expect(setting_exists?("old_setting")).to be false
      expect(setting_exists?("new_setting")).to be true
      expect(setting_value("new_setting")).to eq("some_value")
    end

    it "does not affect other settings" do
      insert_setting("unrelated_setting", "other_value")

      described_class.rename("old_setting", "new_setting")

      expect(setting_value("unrelated_setting")).to eq("other_value")
    end

    it "is a no-op when the source setting does not exist" do
      expect { described_class.rename("nonexistent", "new_name") }.not_to raise_error
    end
  end

  describe ".rename_value" do
    before { insert_setting("my_setting", "old_value") }

    it "updates the value when both name and value match" do
      described_class.rename_value("my_setting", "old_value", "new_value")

      expect(setting_value("my_setting")).to eq("new_value")
    end

    it "does not update when the name matches but value does not" do
      described_class.rename_value("my_setting", "wrong_value", "new_value")

      expect(setting_value("my_setting")).to eq("old_value")
    end

    it "does not update when the value matches but name does not" do
      described_class.rename_value("other_setting", "old_value", "new_value")

      expect(setting_value("my_setting")).to eq("old_value")
    end

    it "is a no-op when neither name nor value match" do
      expect { described_class.rename_value("nonexistent", "nope", "new") }.not_to raise_error
    end
  end
end
