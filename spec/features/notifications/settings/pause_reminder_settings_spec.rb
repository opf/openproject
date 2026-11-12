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

RSpec.describe "Pause reminder settings", :js do
  shared_examples "pause reminder settings" do
    let(:first) { Time.zone.today.beginning_of_month }
    let(:last) { (Time.zone.today.beginning_of_month + 10.days) }
    it "allows to configure the reminder settings" do
      # Save prefs so we can reload them later
      pref.save!

      # Configure the reminders
      reminders_settings_page.visit!

      # By default the pause reminder is unchecked
      reminders_settings_page.expect_paused false

      reminders_settings_page.set_paused(true,
                                         first:,
                                         last:)

      reminders_settings_page.save_paused_reminders

      reminders_settings_page.expect_and_dismiss_flash

      reminders_settings_page.reload!

      reminders_settings_page.expect_paused(true,
                                            first:,
                                            last:)

      pref.reload
      expect(pref.pause_reminders[:enabled]).to be true
      expect(pref.pause_reminders[:first_day]).to eq first.iso8601
      expect(pref.pause_reminders[:last_day]).to eq last.iso8601
    end
  end

  context "with the my page" do
    let(:reminders_settings_page) { Pages::My::Reminders.new(current_user) }
    let(:pref) { current_user.pref }

    current_user do
      create(:user)
    end

    it_behaves_like "pause reminder settings"
  end

  context "with the user administration page" do
    let(:reminders_settings_page) { Pages::Reminders::Settings.new(other_user) }

    let(:other_user) { create(:user) }
    let(:pref) { other_user.pref }

    current_user do
      create(:admin)
    end

    it_behaves_like "pause reminder settings"
  end
end
