# frozen_string_literal: true

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
require Rails.root.join("modules/backlogs/db/migrate/20260422084824_cleanup_backlogs_task_color_from_user_pref")

RSpec.describe CleanupBacklogsTaskColorFromUserPref, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  shared_let(:user) do
    create(:user, preferences: {}) do |user|
      # Add settings including backlogs_task_color which is to be removed
      user.create_preference(
        settings: {
          "theme" => "light",
          "time_zone" => "Etc/UTC",
          "auto_hide_popups" => true,
          "comments_sorting" => "asc",
          "warn_on_leaving_unsaved" => true,
          "backlogs_task_color" => "#52B9C0",
          "disable_keyboard_shortcuts" => false
        }
      )
    end
  end

  it "removes backlogs_task_color from user prefs and leaves the rest" do
    migrate

    expect(user.pref.settings).to eql(
      {
        "theme" => "light",
        "time_zone" => "Etc/UTC",
        "auto_hide_popups" => true,
        "comments_sorting" => "asc",
        "warn_on_leaving_unsaved" => true,
        "disable_keyboard_shortcuts" => false
      }
    )
  end
end
