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

RSpec.describe "Projects admin settings", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }

  current_user { admin }

  before { Setting.enabled_projects_columns = %w[name project_status public] }

  it "allows to change project list columns" do
    visit admin_settings_projects_path

    within "opce-draggable-autocompleter" do
      items = page.all(".op-draggable-autocomplete--item")
      expect(items.map(&:text)).to eq %w[Name Status Public]

      public_item = page.find(".op-draggable-autocomplete--item", text: "Public", exact_text: true)
      public_item.find(".op-draggable-autocomplete--remove-item").click

      # NOTE: Name item cannot be removed
      name_item = page.find(".op-draggable-autocomplete--item", text: "Name", exact_text: true)
      expect(name_item).to have_no_element(".op-draggable-autocomplete--remove-item")

      add_columns = page.find(:combo_box, "Add columns")
      select_autocomplete add_columns.ancestor("ng-select"), query: "Identifier", results_selector: "body"

      items = page.all(".op-draggable-autocomplete--item")
      expect(items.map(&:text)).to eq %w[Name Status Identifier]
    end
    click_on "Save"

    expect_and_dismiss_flash(message: "Successful update")
    within "opce-draggable-autocompleter" do
      items = page.all(".op-draggable-autocomplete--item")
      expect(items.map(&:text)).to eq %w[Name Status Identifier]
    end

    # NOTE: The gantt query settings are tested thoroughly in the projects/lists/gantt_spec.rb
    within "section", text: "Project portfolio Gantt view" do
      expect(page).to have_text "You can modify the query that is used to display Gantt chart from the project overview page."
      expect(page).to have_field "settings[project_gantt_query]", type: :hidden
      expect(page).to have_button "Edit query"
    end

    # Check the effect of the settings change on the projects list page
    projects_page = Pages::Projects::Index.new
    projects_page.visit!
    projects_page.expect_columns_in_order("Name", "Status", "Identifier")
  end
end
