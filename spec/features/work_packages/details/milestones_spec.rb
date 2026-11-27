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

RSpec.describe "Milestones full screen v iew", :js do
  let(:type) { create(:type, is_milestone: true) }
  let(:project) { create(:project, types: [type]) }
  let!(:work_package) do
    create(:work_package,
           project:,
           type:,
           subject: "Foobar")
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }

  before do
    login_as(user)
    wp_page.visit!
  end

  context "user has :add_work_packages permission" do
    let(:user) do
      create(:user, member_with_roles: { project => role })
    end
    let(:role) { create(:project_role, permissions:) }
    let(:permissions) do
      %i[view_work_packages add_work_packages]
    end

    it "shows the button as enabled" do
      click_button("Create", class: "add-work-package")
      expect(page).to have_selector(:menuitem, type.name, exact: true)
    end

    it "opens the type menu from the keyboard and returns focus to the button on Escape" do
      send_keys_without_click(find_button("Create", class: "add-work-package"), :enter)
      expect(page).to have_selector(:menuitem, type.name, exact: true, focused: true)

      page.driver.browser.keyboard.type(:escape)
      expect(page).to have_no_menu
      expect(page).to have_button("Create", class: "add-work-package", focused: true)
    end
  end

  context "user has :view_work_packages permission only" do
    let(:user) do
      create(:user, member_with_roles: { project => role })
    end
    let(:role) { create(:project_role, permissions:) }
    let(:permissions) do
      %i[view_work_packages]
    end

    it "shows the button as correctly disabled" do
      expect(page).to have_css(".add-work-package[aria-disabled='true']", text: "Create")
    end

    it "opens no menu from the disabled button" do
      find(".add-work-package[aria-disabled='true']", text: "Create").click

      wait_for_network_idle
      expect(page).to have_no_menu
    end
  end
end
