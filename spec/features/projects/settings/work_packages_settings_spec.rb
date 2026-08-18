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

RSpec.describe "Projects", "work packages settings menu", :js do
  let!(:project) { create(:project) }
  let(:work_packages_settings_page) { Pages::Projects::Settings::WorkPackages.new(project) }
  let(:general_settings_page) { Pages::Projects::Settings::General.new(project) }

  describe "view settings page" do
    context "when the user has access to types tab" do
      let(:permissions) { %i(edit_project view_work_packages manage_types) }

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      it "displays the types tab" do
        work_packages_settings_page.visit!
        expect(page).to have_css(".tabnav-tab", text: "Types")
        expect(page).to have_css("#types-form")
      end
    end

    context "when the user has access to the categories tab" do
      let(:permissions) { %i(edit_project view_work_packages manage_categories) }

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      it "displays the categories tab" do
        work_packages_settings_page.visit!
        expect(page).to have_css(".tabnav-tab", text: "Categories")
        expect(page).to have_css("span", text: "There are currently no work package categories.")
      end
    end

    context "when the user has access to the internal comments tab", with_ee: %i[internal_comments] do
      let(:permissions) { %i(edit_project view_work_packages) }

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      it "displays the custom fields tab" do
        work_packages_settings_page.visit!
        expect(page).to have_css(".tabnav-tab", text: "Internal Comments")
        expect(page).to have_css("#internal-comments-form")
      end
    end

    context "when the user has access to internal comments tab but not to enterprise" do
      let(:permissions) { %i(edit_project view_work_packages) }

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      it "shows the enterprise banner" do
        work_packages_settings_page.visit!
        expect(page).to have_enterprise_banner(:professional)
      end
    end

    context "when the user does not have access to any tabs" do
      let(:permissions) { %i(view_work_packages) }

      current_user { create(:user, member_with_permissions: { project => permissions }) }

      it "does not display the menu entry" do
        general_settings_page.visit!
        expect(page).to have_no_css(".op-menu--item-title", text: "Work packages")
      end
    end
  end
end
