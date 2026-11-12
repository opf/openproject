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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require Rails.root.join("db/migrate/20250905204438_migrate_theme_preferences.rb")

RSpec.describe MigrateThemePreferences, type: :model do
  let(:user) { create(:user) }

  describe "up migration" do
    it "converts light_high_contrast to new structure without corrupting other settings" do
      user.pref.update(settings: {
                         "theme" => "light_high_contrast",
                         "comments_sorting" => "desc",
                         "time_zone" => "UTC"
                       })

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      user.pref.reload
      expect(user.pref.settings["theme"]).to eq("light")
      expect(user.pref.settings["increase_theme_contrast"]).to be(true)

      # Verify other settings remain intact
      expect(user.pref.settings["comments_sorting"]).to eq("desc")
      expect(user.pref.settings["time_zone"]).to eq("UTC")

      # Verify model methods work correctly for unset auto-contrast settings
      expect(user.pref).not_to be_force_light_theme_contrast
      expect(user.pref).not_to be_force_dark_theme_contrast
    end

    it "converts dark_high_contrast to new structure" do
      user.pref.update(settings: { "theme" => "dark_high_contrast" })

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      user.pref.reload
      expect(user.pref.settings["theme"]).to eq("dark")
      expect(user.pref.settings["increase_theme_contrast"]).to be(true)
    end

    it "leaves existing themes unchanged" do
      user.pref.update(settings: { "theme" => "light", "comments_sorting" => "asc" })

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      user.pref.reload
      expect(user.pref.settings["theme"]).to eq("light")
      expect(user.pref.settings["comments_sorting"]).to eq("asc")
      expect(user.pref.settings).not_to have_key("increase_theme_contrast")

      # Verify model methods work correctly for unset settings
      expect(user.pref).not_to be_increase_theme_contrast
    end
  end

  describe "down migration" do
    it "reverts light theme with contrast back to light_high_contrast" do
      user.pref.update(settings: {
                         "theme" => "light",
                         "increase_theme_contrast" => true,
                         "comments_sorting" => "asc"
                       })

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      user.pref.reload
      expect(user.pref.settings["theme"]).to eq("light_high_contrast")
      expect(user.pref.settings).not_to have_key("increase_theme_contrast")

      # Verify other settings remain intact
      expect(user.pref.settings["comments_sorting"]).to eq("asc")
    end

    it "leaves themes without contrast unchanged" do
      user.pref.update(settings: {
                         "theme" => "sync_with_os",
                         "disable_keyboard_shortcuts" => true
                       })

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      user.pref.reload
      expect(user.pref.settings["theme"]).to eq("sync_with_os")
      expect(user.pref.settings["disable_keyboard_shortcuts"]).to be(true)
    end
  end
end
