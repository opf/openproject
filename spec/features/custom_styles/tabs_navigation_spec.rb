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

RSpec.describe "Tabs navigation and content switching on the admin/design page" do
  shared_let(:admin) { create(:admin) }

  context "without EE token", with_ee: false do
    before do
      login_as(admin)
      visit custom_style_path(tab: "interface")
    end

    it "redirects to upsale page" do
      expect(page).to have_css(".upsale-notification")
    end
  end

  context "with EE token", with_ee: %i[define_custom_style] do
    let(:custom_style) { create (:custom_style_with_logo) }
    let(:image) { "logo" }
    let!(:file_path) { custom_style.send(image).file.path }

    before do
      login_as(admin)
      visit custom_style_path
    end

    it "shows interface tab" do
      expect(page).to have_current_path custom_style_path(tab: "interface")
      expect(page).to have_text I18n.t(:label_interface_colors)
    end

    it "selects a color theme and redirect to the interface tab" do
      select("OpenProject Gray", from: "theme")
      find("[data-test-selector='color-theme-button']").click
      expect_flash(message: I18n.t(:notice_successful_update))
      expect(page).to have_current_path custom_style_path(tab: "interface")
    end

    it "changes accent color and redirects to interface tab" do
      fill_in "design_colors[]accent-color", with: "#333333"
      find("[data-test-selector='interface-colors-button']").click
      expect(page).to have_css("#design_colors_accent-color", value: "#333333")
      expect(page).to have_current_path custom_style_path(tab: "interface")
    end

    it "redirects to branding tab" do
      click_on "Branding"
      expect(page).to have_current_path custom_style_path(tab: "branding")

      # select a color theme and redirect to the branding tab
      select("OpenProject Navy Blue", from: "theme")
      find("[data-test-selector='color-theme-button']").click
      expect_flash(message: I18n.t(:notice_successful_update))
      expect(page).to have_current_path custom_style_path(tab: "branding")

      # remove the logo and redirect to the branding tab
      custom_style.send :remove_logo
      expect(File.exist?(file_path)).to be false
      expect(page).to have_current_path custom_style_path(tab: "branding")
    end

    it "redirects to pdf export styles tab" do
      click_on "PDF export styles"
      expect(page).to have_current_path custom_style_path(tab: "pdf_export_styles")

      # select a color theme and redirect to the PDF export styles tab
      select("OpenProject (default)", from: "theme")
      find("[data-test-selector='color-theme-button']").click
      expect_flash(message: I18n.t(:notice_successful_update))
      expect(page).to have_current_path custom_style_path(tab: "pdf_export_styles")

      # change export cover text color and redirect to the PDF export styles tab
      fill_in "export_cover_text_color", with: "#333"
      find("[data-test-selector='text-color-change']").click
      expect(page).to have_css("#export_cover_text_color", value: "#333")
      expect(page).to have_current_path custom_style_path(tab: "pdf_export_styles")
    end
  end
end
