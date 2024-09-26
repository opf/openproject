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
require Rails.root.join("db/migrate/20240909151818_migrate_legacy_default_theme_to_light_theme.rb")

RSpec.describe MigrateLegacyDefaultThemeToLightTheme, type: :model do
  RSpec::Matchers.define_negated_matcher :not_change, :change

  # Silencing migration logs, since we are not interested in that during testing
  subject(:run_migration) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  shared_let(:user_with_default_theme) { create(:user, preferences: { settings: { theme: "default", foo: "bar" } }) }
  shared_let(:user_with_light_theme) { create(:user, preferences: { settings: { theme: "light", foo: "bar" } }) }
  shared_let(:user_with_light_high_contrast_theme) do
    create(:user, preferences: { settings: { theme: "light_high_contrast", foo: "bar" } })
  end
  shared_let(:user_with_dark_theme) { create(:user, preferences: { settings: { theme: "dark", foo: "bar" } }) }

  it "sets the theme to light for users with the 'default' theme" do
    expect { run_migration }
      .to change { user_with_default_theme.reload.pref.settings["theme"] }
      .from("default")
      .to("light")
  end

  it "does not change the theme for users with another theme that isn't 'default'" do
    expect { run_migration }
      .to not_change { user_with_light_theme.reload.pref.settings["theme"] }
      .and(not_change { user_with_light_high_contrast_theme.reload.pref.settings["theme"] })
      .and(not_change { user_with_dark_theme.reload.pref.settings["theme"] })
  end
end
