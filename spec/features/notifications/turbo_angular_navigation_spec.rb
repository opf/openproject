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

RSpec.describe "Turbo and Angular navigation integration", :js do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }

  shared_let(:work_package) do
    create(:work_package, project:, author: user, subject: "Test Work Package")
  end

  shared_let(:notification) { create(:notification, resource: work_package, recipient: user) }

  let(:center) { Pages::Notifications::Center.new }
  let(:split_screen) { Pages::PrimerizedSplitWorkPackage.new work_package }
  let(:full_screen) { Pages::FullWorkPackage.new work_package }

  before do
    login_as user
  end

  describe "navigation between notification center and work package views" do
    it "reproduces the Turbo/Angular navigation issue with work package sidebar" do
      # Step 1: Open notification center
      center.visit!
      wait_for_reload

      # Wait for notification to be available
      expect(notification).to be_present
      expect(notification.resource).to eq(work_package)

      center.expect_bell_count 1
      center.open

      # Step 2: Click a notification so that the work package opens on the side
      center.click_item notification
      split_screen.expect_open
      center.expect_item_selected notification

      # Step 3: Click on the work package #id from the notifications list
      # This should open the work package in full view
      center.click_id notification
      wait_for_network_idle
      full_screen.expect_subject

      # Step 4: Click back once
      # Expected: Should go back to the notification center with split screen open
      page.go_back
      wait_for_network_idle

      expect(page).to have_current_path(/notifications/)
      split_screen.expect_open

      # Step 5: Click back a second time
      # Expected: Should go back to the notification center, but the work package sidebar is hidden
      page.go_back
      wait_for_network_idle

      expect(page).to have_current_path(/notifications/)
      center.expect_open
      split_screen.expect_closed
    end
  end
end
