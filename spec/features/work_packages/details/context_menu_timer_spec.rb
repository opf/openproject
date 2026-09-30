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

RSpec.describe "Work package single context menu timer", :js do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:wp_view) { Pages::FullWorkPackage.new(work_package, project) }

  before do
    login_as(user)
  end

  context "with a user having permission to log time" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages log_time] }) }

    context "when mobile" do
      include_context "with mobile screen size"

      it "shows the timer entries" do
        wp_view.visit!
        find("#action-show-more-dropdown-menu .button").click

        expect(page).to have_css(".menu-item", text: "Log time")
        expect(page).to have_css(".menu-item", text: "Start timer")
        expect(page).to have_no_css(".menu-item", text: "Stop timer")

        find(".menu-item", text: "Start timer").click
        wait_for_network_idle

        retry_block do
          find("#action-show-more-dropdown-menu .button").click
          expect(page).to have_css(".menu-item", text: "Log time")
          expect(page).to have_css(".menu-item", text: "Stop timer")
          expect(page).to have_no_css(".menu-item", text: "Start timer")
        end
      end
    end

    context "when not mobile" do
      it "does not show the timer entries" do
        wp_view.visit!
        find("#action-show-more-dropdown-menu .button").click

        expect(page).to have_css(".menu-item", text: "Log time")
        expect(page).to have_no_css(".menu-item", text: "Start timer")
        expect(page).to have_no_css(".menu-item", text: "Stop timer")
      end
    end
  end

  context "when user does not have permission to log time" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "does not show the timer entries" do
      wp_view.visit!
      find("#action-show-more-dropdown-menu .button").click

      expect(page).to have_no_css(".menu-item", text: "Log time")
      expect(page).to have_no_css(".menu-item", text: "Start timer")
      expect(page).to have_no_css(".menu-item", text: "Stop timer")
    end
  end
end
