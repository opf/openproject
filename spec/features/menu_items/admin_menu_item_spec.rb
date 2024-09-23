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

RSpec.describe "Admin menu items",
               :js,
               :with_cuprite do
  shared_let(:user) { create(:admin) }

  before do
    login_as user
    visit admin_index_path
  end

  after do
    OpenProject::Configuration["hidden_menu_items"] = []
  end

  context "without having any menu items hidden in configuration" do
    it "must display all menu items" do
      expect(page).to have_test_selector("menu-blocks--container")
      expect(page).to have_test_selector("menu-block", count: 21)
      expect(page).to have_test_selector("op-menu--item-action", count: 22) # All plus 'overview'
    end
  end

  context "having custom hidden menu items",
          with_config: {
            "hidden_menu_items" => { "admin_menu" => ["colors"] }
          } do
    it "must not display the hidden menu items and blocks" do
      expect(page).to have_test_selector("menu-blocks--container")
      expect(page).to have_test_selector("menu-block", count: 20)
      expect(page).not_to have_test_selector("menu-block", text: I18n.t(:label_color_plural))

      expect(page).to have_test_selector("op-menu--item-action", count: 21) # All plus 'overview'
      expect(page).not_to have_test_selector("op-menu--item-action", text: I18n.t(:label_color_plural))
    end
  end

  context "when logged in with a non-admin user with specific admin permissions" do
    shared_let(:user) { create(:user, global_permissions: %i[manage_user create_backup]) }

    it "must display only the actions allowed by global permissions" do
      expect(page).to have_test_selector("menu-block", text: I18n.t("label_user_plural"))
      expect(page).to have_test_selector("menu-block", text: I18n.t("label_backup"))
      expect(page).to have_test_selector("op-menu--item-action", text: I18n.t("label_user_plural"))
      expect(page).to have_test_selector("op-menu--item-action", text: I18n.t("label_backup"))
    end
  end
end
