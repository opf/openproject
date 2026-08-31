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

RSpec.describe "Project attribute help texts", :js do
  let!(:project) { create(:project) }

  let!(:name_help_text) do
    create(
      :project_help_text,
      attribute_name: :name,
      help_text: "Some **help text** for name."
    )
  end

  let!(:description_help_text) do
    create(
      :project_help_text,
      attribute_name: :description,
      help_text: "Some **help text** for description."
    )
  end

  let!(:status_help_text) do
    create(
      :project_help_text,
      attribute_name: :status,
      help_text: "Some **help text** for status."
    )
  end

  let(:grid) do
    grid = create(:grid)
    grid.widgets << create(:grid_widget,
                           identifier: "project_status",
                           options: { "name" => "Status" },
                           start_row: 1,
                           end_row: 2,
                           start_column: 1,
                           end_column: 1)
  end

  before do
    login_as user
  end

  shared_examples "allows to view help texts" do |show_edit:|
    it "shows help text modal on clicking help text link" do
      visit dashboard_project_overview_path(project)

      wait_for_network_idle
      expect(page).to have_css("#{test_selector('op-widget-box--header')} .help-text--entry", wait: 10)

      # Open help text modal
      page.find("[data-qa-help-text-for='description").click

      expect(page).to have_modal "Description"
      within_modal "Description" do
        expect(page).to have_css("strong", text: "help text")

        expect(page).to have_button "Close"
        if show_edit
          expect(page).to have_link "Edit"
        end

        click_on "Close"
      end

      expect(page).to have_no_modal "Description"
    end
  end

  describe "as admin" do
    let(:user) { create(:admin) }

    it_behaves_like "allows to view help texts", show_edit: true

    it "shows the help text on the project create form" do
      visit new_project_path

      # Step 1: Select workspace type (blank project)
      click_on "Continue"

      # Step 2: Project details - Name field is visible here
      expect(page).to have_field "Name"

      within(:element, "label", text: "Name") do
        click_on accessible_name: "Show help text"
      end

      expect(page).to have_modal "Name"

      within_modal "Name" do
        expect(page).to have_css "strong", text: "help text"

        expect(page).to have_button "Close"
        expect(page).to have_link "Edit"

        click_on "Close"
      end

      expect(page).not_to have_modal "Name"
    end
  end

  describe "as regular user" do
    let(:user) do
      create(:user, member_with_permissions: { project => [:view_project] })
    end

    it_behaves_like "allows to view help texts", show_edit: false
  end
end
