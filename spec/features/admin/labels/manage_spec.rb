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

RSpec.describe "Managing labels", :js, with_flag: { work_package_labels: true } do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  def row_selector(label)
    "label-row-#{label.id}"
  end

  def within_row_menu(label, &)
    within_test_selector(row_selector(label)) do
      find_test_selector("label-row-menu").click_link_or_button
      within("anchored-position", &)
    end
  end

  def expect_row(label, usage:)
    within_test_selector(row_selector(label)) do
      expect(page).to have_test_selector("label-name", text: label.name)
      expect(page).to have_test_selector("label-usage", text: usage)
    end
  end

  it "shows the menu entry and a blank slate" do
    visit admin_index_path

    within("#menu-sidebar") do
      expect(page).to have_link("Labels", href: %r{/admin/labels\z})
      click_link "Labels"
    end

    expect(page).to have_css(".PageHeader-title", text: "Labels")
    expect(page).to have_css(".blankslate", text: "No labels yet")
  end

  it "creates a label, rejecting a blank name first" do
    visit admin_labels_path

    find_test_selector("add-label-button").click
    page.within_modal("Create label") do
      click_on "Create"
      expect(page).to have_button("Create")
      expect(Label.count).to eq(0)

      fill_in "Name", with: "Machine Learning"
      click_on "Create"
    end

    expect_flash(message: "Successful creation.")
    label = Label.find_by!(name: "Machine Learning")
    expect_row(label, usage: "-")
  end

  it "renames a label, rejecting a case-insensitive duplicate first" do
    label = create(:label, name: "Machine Learning")
    create(:label, name: "Neural learning")

    visit admin_labels_path

    within_row_menu(label) { click_on "Rename" }
    page.within_modal('Rename "Machine Learning"') do
      fill_in "Name", with: "neural learning"
      wait_for_turbo_stream { click_on "Rename" }
      expect(page).to have_text("A label with this name already exists. Please use another one.")

      fill_in "Name", with: "Deep learning"
      click_on "Rename"
    end

    expect_flash(message: "Successful update.")
    expect_row(label.reload, usage: "-")
    expect(label.name).to eq("Deep learning")
  end

  it "deletes a label along with its labelings" do
    label = create(:label, name: "Deprecated")
    create_list(:labeling, 2, label:)

    visit admin_labels_path

    expect_row(label, usage: "2 work packages")

    within_row_menu(label) { click_on "Delete" }
    page.within_modal("Delete this label?") do
      check "I understand that this action is not reversible"
      click_on "Delete"
    end

    expect_flash(message: "Successful deletion.")
    expect(page).to have_no_test_selector(row_selector(label))
    expect(Label.where(id: label.id)).not_to exist
    expect(Labeling.where(label_id: label.id)).not_to exist
  end

  it "searches the label list and paginates the results",
     with_settings: { per_page_options: "2 5 10" } do
    alpha = create(:label, name: "Alpha")
    beta = create(:label, name: "Beta")
    gamma = create(:label, name: "Gamma")

    visit admin_labels_path

    expect(page).to have_test_selector(row_selector(alpha))
    expect(page).to have_test_selector(row_selector(beta))
    expect(page).to have_no_test_selector(row_selector(gamma))
    expect(page).to have_css(".op-pagination")

    fill_in "Search", with: "gam"
    wait_for_network_idle
    expect(page).to have_test_selector(row_selector(gamma))
    expect(page).to have_no_test_selector(row_selector(alpha))

    fill_in "Search", with: "zzz"
    wait_for_network_idle
    expect(page).to have_css(".blankslate", text: "No labels match your search")

    fill_in "Search", with: ""
    wait_for_network_idle
    expect(page).to have_test_selector(row_selector(alpha))
    expect(page).to have_test_selector(row_selector(beta))
  end

  it "hides the menu entry and the page when the feature flag is inactive",
     with_flag: { work_package_labels: false } do
    visit admin_index_path

    within("#menu-sidebar") { expect(page).to have_no_link("Labels") }

    visit admin_labels_path
    expect(page).to have_text("[Error 404]")
  end
end
