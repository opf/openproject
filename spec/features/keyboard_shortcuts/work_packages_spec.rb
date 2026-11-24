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
require "features/work_packages/work_packages_page"

RSpec.describe "Work package keyboard shortcuts", :js do
  shared_let(:project) { create(:project_with_types, enabled_module_names: %w[work_package_tracking calendar_view]) }
  shared_let(:work_package) { create(:work_package, project:, subject: "Keyboard subject") }

  let(:user) { create(:admin) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:split_view) { Pages::SplitWorkPackage.new(work_package, project) }
  let(:full_view) { Pages::FullWorkPackage.new(work_package, project) }
  let(:global_search) { Components::GlobalSearch.new }

  before { login_as(user) }

  describe "on the work package list" do
    before do
      wp_table.visit!
      wp_table.expect_work_package_listed(work_package)
    end

    it "m opens More actions" do
      expect(page).to have_button(accessible_name: "More actions")
      page.send_keys("m")

      expect(page).to have_menu("More actions")
    end

    it "n w p and the Create button open the type dropdown" do
      expect(page).to have_button("Create")
      expect(page).to have_element(accesskey: "2", count: 1, visible: :all)

      page.send_keys("n", "w", "p")
      expect(page).to have_selector(:menuitem, work_package.type.name)
      expect(page).to have_current_path(project_work_packages_path(project), ignore_query: true)

      page.send_keys(:escape)
      expect(page).to have_no_menu

      click_on "Create"
      expect(page).to have_selector(:menuitem, work_package.type.name)
    end

    it "d w p opens the split view" do
      expect(page).to have_button(accessible_name: "Open details view")
      page.send_keys("d", "w", "p")

      split_view.expect_open
    end

    it "fires nothing while typing in the filter text field" do
      Components::WorkPackages::Filters.new.open
      input = find_field("filter-by-text-input")
      input.click
      page.send_keys("g", "e", "m")

      expect(input.value).to eq("gem")
      expect(page).to have_no_menu
    end
  end

  describe "in the split view" do
    before do
      split_view.visit!
      split_view.expect_open
    end

    it "m follows the details More and returns to the list More actions after closing" do
      expect(page).to have_button(accessible_name: "More")
      page.send_keys("m")
      expect(page).to have_menu("More")
      page.send_keys(:escape)
      expect(page).to have_no_menu

      find(:button, accessible_name: "Close details view").click
      split_view.expect_closed
      expect(page).to have_element(accesskey: "7", count: 1, visible: :all)
      expect(page).to have_button(accessible_name: "More actions")

      page.send_keys("m")
      expect(page).to have_menu("More actions")
    end

    it "g e edits the subject" do
      within(".work-packages--subject-type-row") { expect(page).to have_button("Edit subject", exact: true) }
      page.send_keys("g", "e")

      split_view.edit_field(:subject).expect_active!
    end
  end

  describe "in the full view" do
    before do
      full_view.visit!
      full_view.ensure_page_loaded
    end

    it "m opens More" do
      expect(page).to have_button(accessible_name: "More")
      page.send_keys("m")

      expect(page).to have_menu("More")
    end

    it "n w p opens the new work package form" do
      page.send_keys("n", "w", "p")

      expect(page).to have_current_path(new_project_work_packages_path(project))
    end

    it "g e edits the subject and typing appends to it" do
      within(".work-packages--subject-type-row") { expect(page).to have_button("Edit subject", exact: true) }
      page.send_keys("g", "e")
      subject_field = full_view.edit_field(:subject)
      subject_field.expect_active!

      page.send_keys("!")

      expect(subject_field.input_element.value).to eq("Keyboard subject!")
    end

    context "when inline edit requires a double click" do
      let(:user) do
        create(:admin, preferences: { settings: { require_double_click_for_inline_edit: true } })
      end

      it "g e still edits the subject" do
        within(".work-packages--subject-type-row") { expect(page).to have_button("Edit subject", exact: true) }
        page.send_keys("g", "e")

        full_view.edit_field(:subject).expect_active!
      end
    end
  end

  describe "in the calendar" do
    let(:query) { create(:query_with_view_work_packages_calendar, user:, project:, public: false) }

    it "m does not open the calendar settings" do
      visit project_calendar_path(project, id: query.id)
      expect(page).to have_button(accessible_name: "More actions")

      page.send_keys("m")
      sleep 0.5

      expect(page).to have_no_menu
    end
  end

  describe "s" do
    def expect_search_takes_typed_text
      expect(page).to have_element(:button, "data-hotkey": "s", visible: :all)
      page.send_keys("s")

      expect(global_search.input).to match_selector(":focus")
      expect(global_search.input.value).to eq("")

      page.send_keys("a", "b", "c")

      expect(global_search.input.value).to eq("abc")
    end

    it "focuses global search with an empty query" do
      visit search_path(q: "earlier")

      expect_search_takes_typed_text
    end

    it "focuses global search at a narrow viewport" do
      page.current_window.resize_to(500, 900)
      visit project_path(project)

      expect_search_takes_typed_text
    ensure
      page.current_window.resize_to(1920, 1080)
    end
  end

  describe "access key 4" do
    # A native access key activation clicks its owner, the visually hidden button behind the s hotkey.
    def activate_search_access_key
      expect(page).to have_element(accesskey: "4", count: 1, visible: :all)
      find(:element, :button, accesskey: "4", "data-hotkey": "s", visible: :all).execute_script("this.click()")
    end

    it "focuses global search and keeps the current query at desktop width" do
      visit search_path(q: "earlier")

      activate_search_access_key

      expect(global_search.input).to match_selector(":focus")
      expect(global_search.input.value).to eq("earlier")
    end

    it "opens global search and keeps the current query at a narrow viewport" do
      page.current_window.resize_to(500, 900)
      visit search_path(q: "earlier")

      activate_search_access_key

      expect(global_search.input).to match_selector(":focus")
      expect(global_search.input.value).to eq("earlier")
    ensure
      page.current_window.resize_to(1920, 1080)
    end

    context "with keyboard shortcuts disabled" do
      before { user.pref.update!(disable_keyboard_shortcuts: true) }

      it "opens global search at a narrow viewport" do
        page.current_window.resize_to(500, 900)
        visit project_path(project)

        activate_search_access_key

        expect(global_search.input).to match_selector(":focus")
        page.send_keys("a", "b", "c")
        expect(global_search.input.value).to eq("abc")
      ensure
        page.current_window.resize_to(1920, 1080)
      end
    end
  end

  describe "the search magnifier at a narrow viewport" do
    before { page.current_window.resize_to(500, 900) }
    after { page.current_window.resize_to(1920, 1080) }

    def magnifier = find_by_id("top-menu-search-button")

    it "opens search with the current query" do
      visit search_path(q: "earlier")

      magnifier.click

      expect(global_search.input).to match_selector(":focus")
      expect(global_search.input.value).to eq("earlier")
    end

    it "keeps typed text when search closes and opens again" do
      visit project_path(project)
      magnifier.click
      expect(global_search.input).to match_selector(":focus")
      page.send_keys("typed-before-close")

      find(:button, class: "top-menu-search--back-button").click
      magnifier.click

      expect(global_search.input.value).to eq("typed-before-close")
    end
  end

  describe "in a collaborative document", :selenium,
           with_settings: { real_time_text_collaboration_enabled: true } do
    include_context "with hocuspocus"

    let(:document) { create(:document, :collaborative) }
    let(:editor) { FormFields::Primerized::BlockNoteEditorInput.new }

    it "keeps typed text in the editor and leaves search closed" do
      visit document_path(document)
      expect(page).to have_test_selector("blocknote-document-description")

      editor.fill_in("ask")

      editor.wait_for_shadow_content("ask")
      expect(global_search.input).not_to match_selector(":focus")
      expect(page).to have_no_element(class: "op-app-header_search-open")
    end
  end
end
