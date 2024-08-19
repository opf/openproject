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

RSpec.describe "Top menu items", :js do
  shared_let(:project) { create(:project) }

  let(:user) { create(:user) }
  let(:open_menu) { true }

  def has_menu_items?(*labels)
    within ".op-app-header" do
      labels.each do |l|
        expect(page).to have_link(l)
      end
    end
  end

  def expect_no_menu_item(*labels)
    within ".op-app-header" do
      labels.each do |l|
        expect(page).to have_no_link(l)
      end
    end
  end

  def click_link_in_open_menu(title)
    # if the menu is not completely expanded (e.g. if the frontend thread is too fast),
    # the click might be ignored

    within "#op-app-header--modules-menu-list" do
      expect(page).to have_no_css("[style~=overflow]")

      page.click_link(title)
    end
  end

  before do |ex|
    allow(User).to receive(:current).and_return user
    create(:anonymous_role)
    create(:non_member)

    if ex.metadata.key?(:allow_all_permissions)
      mock_permissions_for(user, &:allow_everything)
    end

    visit root_path
    top_menu.click if open_menu
  end

  describe "Modules" do
    let!(:top_menu) { page.find_test_selector("op-app-header--modules-menu-button") }

    let(:reporting_item) { I18n.t("cost_reports_title") }

    context "as an admin" do
      let(:user) { create(:admin) }

      it "displays reporting item" do
        has_menu_items?(reporting_item)
      end

      it "visits the reporting page" do
        click_link_in_open_menu(reporting_item)
        expect(page).to have_current_path(url_for(controller: "/cost_reports", action: "index", project_id: nil, only_path: true))
      end
    end

    context "as a regular user" do
      it "has no menu item" do
        expect_no_menu_item reporting_item
      end
    end

    context "as a user with permissions", :allow_all_permissions do
      it "displays all options" do
        has_menu_items?(reporting_item)
      end
    end
  end
end
