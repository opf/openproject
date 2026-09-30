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

RSpec.describe "Work package single context menu", :js, :selenium do
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package) }

  let(:wp_view) { Pages::FullWorkPackage.new(work_package, work_package.project) }

  before do
    login_as(user)
    wp_view.visit!
  end

  it "sets the correct duplicate work package link" do
    wp_view.select_from_context_menu("Duplicate in another project")

    expect(page).to have_css("h2", text: I18n.t(:button_duplicate))
    expect(page).to have_css("a.work_package", text: "##{work_package.id}")
    expect(page).to have_current_path /work_packages\/move\/new\?copy=true&ids\[\]=#{work_package.id}/
  end

  it "successfully copies the short url of the work package" do
    wp_view.select_from_context_menu("Copy link to clipboard")

    # We cannot access the navigator.clipboard from a headless browser.
    # This test makes sure the copy to clipboard logic is working,
    # regardless of the browser permissions.
    # It can either succeed (showing success message) or fail (showing the URL to copy manually).
    expect(page).to have_message_copied_to_clipboard("/wp/#{work_package.id}")
  end

  describe "'Copy numeric ID to clipboard' item" do
    context "in classic (numeric) mode", with_settings: { work_packages_identifier: "classic" } do
      it "is not offered (the displayed id is already the numeric id)" do
        find("button[wpsinglecontextmenu]").click
        within(".op-context-menu--overlay") do
          expect(page).to have_no_css(".menu-item", text: "Copy numeric ID to clipboard")
        end
      end
    end

    context "in semantic mode", with_settings: { work_packages_identifier: "semantic" } do
      it "is offered" do
        find("button[wpsinglecontextmenu]").click
        within(".op-context-menu--overlay") do
          expect(page).to have_css(".menu-item", text: "Copy numeric ID to clipboard")
        end
      end
    end
  end
end
