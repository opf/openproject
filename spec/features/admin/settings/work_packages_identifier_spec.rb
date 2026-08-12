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

RSpec.describe "Work packages identifier admin settings", :js do
  shared_let(:admin) { create(:admin) }

  before do
    login_as(admin)
  end

  let(:settings_path) { "/admin/settings/work_packages_identifier" }

  def visit_settings
    visit settings_path
    # Wait for the radio group legend to confirm the page has loaded
    expect(page).to have_css("legend", text: "Work package identifier", wait: 10)
  end

  context "when no projects have problematic identifiers" do
    it "saves the setting without showing a dialog" do
      visit_settings
      choose "Project-based semantic identifiers"

      click_button "Convert identifiers"

      expect(page).to have_current_path(settings_path)
      expect(page).to have_no_dialog
    end
  end

  context "when a project has a problematic identifier" do
    shared_let(:project) { create(:project, identifier: "bad-id", name: "Bad Project") }

    context "when switching from semantic to classic", with_settings: { work_packages_identifier: "semantic" } do
      it "saves without showing the confirmation dialog" do
        visit_settings
        choose "Instance-wide numerical sequence (default)"

        # The autofix section is hidden when classic is selected
        expect(page).to have_css(
          "[data-admin--work-packages-identifier-target=autofixSection][hidden]",
          visible: :all
        )
        click_button "Convert identifiers"

        expect(page).to have_current_path(settings_path)
        expect(page).to have_no_dialog
      end
    end

    context "when switching to semantic" do
      before do
        visit_settings
        choose "Project-based semantic identifiers"
      end

      it "shows the autofix section after selecting semantic" do
        expect(page).to have_css(
          "[data-admin--work-packages-identifier-target=autofixSection]:not([hidden])",
          visible: :visible
        )
      end

      it "opens the confirmation dialog when 'Convert identifiers' is clicked" do
        click_on "Convert identifiers"

        expect(page).to have_dialog "Change work package identifiers"
      end

      it "shows the dialog heading and checkbox" do
        click_on "Convert identifiers"

        within_dialog "Change work package identifiers" do
          expect(page).to have_text("Enable project-based work package IDs?")
          expect(page).to have_field(
            "I understand that this will permanently change all work package IDs",
            type: :checkbox
          )
        end
      end

      it "enables the confirm button only after checking the checkbox" do
        click_on "Convert identifiers"

        within "[role=alertdialog]" do
          expect(page).to have_button("Change identifiers", disabled: true)

          check "I understand that this will permanently change all work package IDs"

          expect(page).to have_button("Change identifiers", disabled: false)
        end
      end

      it "hides the plain Save button when autofix section is visible" do
        expect(page).to have_no_button("Convert identifiers")
        expect(page).to have_link("Convert identifiers")
      end
    end
  end
end
