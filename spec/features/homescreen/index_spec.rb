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

RSpec.describe "Homescreen", "index", :with_cuprite do
  let(:admin) { create(:admin) }
  let(:user) { build_stubbed(:user) }
  let!(:project) { create(:public_project, identifier: "public-project") }
  let(:general_settings_page) { Pages::Admin::SystemSettings::General.new }

  it "is reachable by the global menu" do
    login_as user
    visit root_url

    within "#main-menu" do
      click_on "Home"
    end

    expect(page).to have_current_path(home_path)
  end

  context "with a dynamic URL in the welcome text" do
    before do
      Setting.welcome_text = "With [a link to the public project]({{opSetting:base_url}}/projects/public-project)"
      Setting.welcome_on_homescreen = true
    end

    it "renders the correct link" do
      login_as user
      visit root_url
      expect(page)
        .to have_css("a[href=\"#{Rails.application.root_url}/projects/public-project\"]")

      click_link "a link to the public project"
      expect(page).to have_current_path project_path(project)
    end

    it "can change the welcome text and still have a valid link", :js do
      login_as admin

      general_settings_page.visit!

      welcome_text_editor = general_settings_page.welcome_text_editor
      scroll_to_element(welcome_text_editor.container)
      welcome_text_editor.click_and_type_slowly("Hello! ")

      general_settings_page.press_save_button
      general_settings_page.expect_and_dismiss_toaster

      visit root_url
      expect(page)
        .to have_css("a[href=\"#{Rails.application.root_url}/projects/public-project\"]")

      click_link "a link to the public project"
      expect(page).to have_current_path /#{Regexp.escape(project_path(project))}\/?$/
    end
  end

  describe "Enterprise Support Link" do
    include_context "support links"

    context "on an Enterprise Edition" do
      before do
        allow(EnterpriseToken).to receive(:active?).and_return(true)
      end

      it "renders the correct link" do
        login_as user
        visit root_url
        expect(page).to have_link(I18n.t(:label_enterprise_support),
                                  href: support_link_as_enterprise)
      end
    end

    context "on a Community Edition" do
      before do
        allow(EnterpriseToken).to receive(:active?).and_return(false)
      end

      it "renders the correct link" do
        login_as user
        visit root_url
        expect(page).to have_link(I18n.t(:label_enterprise_support),
                                  href: support_link_as_community)
      end
    end
  end
end
