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

RSpec.describe "Switching to project from a notification", :js do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }
  shared_let(:work_package) { create(:work_package, project:, author: user, subject: "Test Work Package") }
  shared_let(:notification) { create(:notification, resource: work_package, recipient: user) }

  let(:center) { Pages::Notifications::Center.new }
  let(:split_screen) { Pages::PrimerizedSplitWorkPackage.new work_package }

  before do
    login_as user
  end

  # Regression OP-19605: the split screen renders inside a Turbo Frame, so the
  # project link needs target="_top" to escape it. Without it, the click is
  # swallowed by a frame navigation that goes nowhere.
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
end
