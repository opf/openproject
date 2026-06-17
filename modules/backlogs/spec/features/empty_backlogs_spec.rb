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
require_relative "../support/pages/backlog"

RSpec.describe "Empty backlogs project",
               :js do
  shared_let(:story) { create(:type_feature) }
  shared_let(:task) { create(:type_task) }
  shared_let(:project) { create(:project, types: [story, task], enabled_module_names: %w(backlogs)) }
  shared_let(:status) { create(:status, is_default: true) }
  let(:planning_page) { Pages::Backlog.new(project) }

  before do
    login_as current_user
    planning_page.visit!
  end

  context "as admin" do
    let(:current_user) { create(:admin) }

    it "shows blankslate with description" do
      within "#owner_backlogs_container .blankslate" do
        expect(page).to have_heading("Backlog inbox is empty", exact: true)
        expect(page).to have_text("All open work packages in this project will automatically appear here.")
      end

      within "#sprint_backlogs_container .blankslate" do
        expect(page).to have_heading("No sprints present yet", exact: true)
        expect(page).to have_text("To start planning your sprint, create one here")
        expect(page).to have_link("project settings")
      end
    end
  end

  context "as regular member" do
    let(:role) { create(:project_role, permissions: %i(view_sprints)) }
    let(:current_user) { create(:user, member_with_roles: { project => role }) }

    it "shows a blankslate without description" do
      within "#owner_backlogs_container .blankslate" do
        expect(page).to have_heading("Backlog inbox is empty", exact: true)
        expect(page).to have_text("All open work packages in this project will automatically appear here.")
      end

      within "#sprint_backlogs_container .blankslate" do
        expect(page).to have_heading("No sprints present yet", exact: true)
        expect(page).to have_text("No sprints are available for this project yet.")
      end
    end
  end
end
