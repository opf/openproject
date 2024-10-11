# -- copyright
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
# ++

require "spec_helper"
require Rails.root.join("db/migrate/20241002151949_remove_hide_mail_from_user_preferences.rb")

RSpec.describe RemoveHideMailFromUserPreferences, type: :model do
  # Silencing migration logs, since we are not interested in that during testing
  subject(:run_migration) do
    perform_enqueued_jobs do
      ActiveRecord::Migration.suppress_messages { described_class.new.up }
    end
  end

  context "when hide_mail user preference exists" do
    before do
      create(:user_preference, settings: { hide_mail: true, other: "setting" })
    end

    it "removes the flag" do
      run_migration
      expect(UserPreference.first.settings).to eq({ "other" => "setting" })
    end
  end

  context "when hide_mail user preference does not exists" do
    before do
      create(:user_preference, settings: { other: "setting" })
    end

    it "does nothing" do
      run_migration
      expect(UserPreference.first.settings).to eq({ "other" => "setting" })
    end
  end
end
