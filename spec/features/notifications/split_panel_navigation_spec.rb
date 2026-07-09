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

RSpec.describe "Split panel navigation in the notification center", :js do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }
  shared_let(:work_package) { create(:work_package, project:, author: user, subject: "Test Work Package") }
  shared_let(:notification) { create(:notification, resource: work_package, recipient: user) }

  let(:center) { Pages::Notifications::Center.new }
  let(:split_screen) { Pages::PrimerizedSplitWorkPackage.new work_package }

  before do
    login_as user
  end

  # The split panel (content-bodyRight Turbo Frame) defaults to full-page navigation (target="_top"),
  # so content links escape the frame instead of being swallowed by a frame navigation that goes nowhere.
  it "navigates to the project when clicking the project context link" do
    center.visit!
    center.expect_bell_count 1
    center.open

    center.click_item notification
    split_screen.expect_open
    split_screen.switch_to_tab tab: "overview"

    link = page.find(".project-context--switch-link")
    expect(link[:href]).to include(project_path(project.id))

    link.click
    wait_for_network_idle
    expect(page).to have_current_path(project_path(project.id))
  end

  # The inverse of the above: tab switching and closing must stay *inside* the frame.
  # A regression to a full-page visit would re-render the whole body, so we tag a node
  # outside the frame (the Angular notification center) and assert it survives.
  it "keeps tab switching and closing inside the split panel" do
    center.visit!
    center.expect_bell_count 1
    center.open

    center.click_item notification
    split_screen.expect_open
    mark_surrounding_page

    split_screen.switch_to_tab tab: "overview"
    split_screen.expect_tab "overview"
    expect_surrounding_page_preserved

    split_screen.close
    split_screen.expect_closed
    expect_surrounding_page_preserved
  end

  def mark_surrounding_page
    page.execute_script("document.querySelector('opce-notification-center').dataset.frameRegressionMarker = '1'")
  end

  def expect_surrounding_page_preserved
    expect(page).to have_css("opce-notification-center[data-frame-regression-marker='1']")
  end
end
