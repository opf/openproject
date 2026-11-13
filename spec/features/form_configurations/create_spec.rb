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

RSpec.describe "Creating a standalone form", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }

  before { login_as admin }

  it "creates a form from scratch and lands on its own page", :aggregate_failures do
    visit form_configurations_path
    wait_for_turbo_stream { click_on "Form", exact: true }

    within_dialog I18n.t("form_configurations.start.title") do
      find_test_selector("form_configuration-start-scratch").click
      expect(page).to have_css("[data-test-selector='form_configuration-start-scratch']:checked", visible: :all)
      click_on I18n.t(:button_continue)
    end

    fill_in "Form name", with: "Release form"
    fill_in "Description", with: "How releases are captured"
    click_on I18n.t(:button_create)

    expect(page).to have_current_path(%r{/forms/\d+/edit})
    expect(page).to have_text("Release form")
    expect(FormConfiguration.find_by(name: "Release form").description).to eq("How releases are captured")
  end

  it "copies the attribute groups of the form it starts from" do
    create(:form_configuration, name: "Standard form").update!(attribute_groups: [["People", %w[assignee]]])

    visit form_configurations_path
    wait_for_turbo_stream { click_on "Form", exact: true }

    within_dialog I18n.t("form_configurations.start.title") do
      find_test_selector("form_configuration-start-copy").click
      select_autocomplete(find_test_selector("form_configuration-copy-source"),
                          query: "Standard",
                          results_selector: "#form_configuration-dialog")
      click_on I18n.t(:button_continue)
    end

    fill_in "Form name", with: "Copied form"
    click_on I18n.t(:button_create)

    expect(page).to have_current_path(%r{/forms/\d+/edit})
    expect(FormConfiguration.find_by(name: "Copied form").attribute_groups.map(&:key)).to eq(%w[People])
  end

  it "refuses a name another form already has", :aggregate_failures do
    create(:form_configuration, name: "Standard form")

    visit form_configurations_path
    wait_for_turbo_stream { click_on "Form", exact: true }

    within_dialog I18n.t("form_configurations.start.title") do
      find_test_selector("form_configuration-start-scratch").click
      expect(page).to have_css("[data-test-selector='form_configuration-start-scratch']:checked", visible: :all)
      click_on I18n.t(:button_continue)
    end

    fill_in "Form name", with: "Standard form"
    click_on I18n.t(:button_create)

    expect(page).to have_css("#form_configuration-dialog")
    expect(page).to have_text("Name has already been taken")
  end

  it "lists the new form on the index" do
    visit form_configurations_path
    wait_for_turbo_stream { click_on "Form", exact: true }

    within_dialog I18n.t("form_configurations.start.title") do
      find_test_selector("form_configuration-start-scratch").click
      click_on I18n.t(:button_continue)
    end

    fill_in "Form name", with: "Release form"
    click_on I18n.t(:button_create)
    expect(page).to have_current_path(%r{/forms/\d+/edit})

    visit form_configurations_path

    expect(page).to have_text("Release form")
  end
end
