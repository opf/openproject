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
require Rails.root.join("db/migrate/20251017111720_set_anonymous_user_theme_to_sync_with_os.rb")

RSpec.describe SetAnonymousUserThemeToSyncWithOs, type: :model do
  let(:anonymous_user) { User.anonymous }

  before do
    # Ensure the anonymous user has a preference entry
    anonymous_user.pref.update(settings: { "theme" => "light" })
  end

  describe "up migration" do
    it "sets the anonymous user theme to sync_with_os" do
      expect(anonymous_user.pref.settings["theme"]).to eq("light")

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      anonymous_user.pref.reload
      expect(anonymous_user.pref.settings["theme"]).to eq("sync_with_os")
    end

    it "does not affect other users" do
      other_user = create(:user)
      other_user.pref.update(settings: { "theme" => "dark" })

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      other_user.pref.reload
      expect(other_user.pref.settings["theme"]).to eq("dark")
    end
  end

  describe "down migration" do
    it "reverts the anonymous user theme back to light" do
      anonymous_user.pref.update(settings: { "theme" => "sync_with_os" })

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      anonymous_user.pref.reload
      expect(anonymous_user.pref.settings["theme"]).to eq("light")
    end

    it "does not modify other user preferences" do
      other_user = create(:user)
      other_user.pref.update(settings: { "theme" => "dark" })

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      other_user.pref.reload
      expect(other_user.pref.settings["theme"]).to eq("dark")
    end
  end
end
