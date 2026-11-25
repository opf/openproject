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

RSpec.describe "Work package index accessibility" do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }

  def visit_index_page
    work_packages_page.visit_index
  end

  before do
    login_as(user)

    work_package
  end

  after do
    work_packages_page.ensure_loaded
  end

  describe "Sort link", :js do
    before { visit_index_page }

    shared_examples_for "sortable column" do
      def sort_from_column_menu(item)
        find(:columnheader, column_name).click_button(column_name)
        within(:menu, column_name) { find(:role, "menuitemradio", text: item).click }
      end

      it "sorts descending from the column menu" do
        sort_from_column_menu("Sort descending")

        expect(page).to have_selector(:columnheader, column_name, aria: { sort: "descending" })
      end

      it "sorts ascending from the column menu" do
        sort_from_column_menu("Sort ascending")

        expect(page).to have_selector(:columnheader, column_name, aria: { sort: "ascending" })
      end
    end

    describe "id column" do
      let(:column_name) { "ID" }

      it_behaves_like "sortable column"
    end

    describe "subject column" do
      let(:column_name) { "Subject" }

      it_behaves_like "sortable column"
    end

    describe "type column" do
      let(:column_name) { "Type" }

      it_behaves_like "sortable column"
    end

    describe "status column" do
      let(:column_name) { "Status" }

      it_behaves_like "sortable column"
    end

    describe "assigned to column" do
      let(:column_name) { "Assignee" }

      it_behaves_like "sortable column"
    end
  end

  describe "hotkeys", :js do
    let!(:another_work_package) do
      create(:work_package,
             project:)
    end

    before do
      visit_index_page
    end

    context "focus" do
      let(:first_row_selector) do
        ".wp-row-#{work_package.id}"
      end
      let(:second_row_selector) do
        ".wp-row-#{another_work_package.id}"
      end

      it "navigates with J and K" do
        expect(page).to have_css(".wp-row-#{work_package.id}")
        expect(page).to have_css(".wp-row-#{another_work_package.id}")

        find("body").send_keys("j")
        expect(page).to have_focus_on(first_row_selector)

        # Avoid sending keys on body since that resets focus
        send_keys_without_click(page.active_element, "j")
        expect(page).to have_focus_on(second_row_selector)

        send_keys_without_click(page.active_element, "k")
        expect(page).to have_focus_on(first_row_selector)
      end
    end

    context "help" do
      it "opens help popup with '?'" do
        expect_angular_frontend_initialized

        new_window = window_opened_by { find("body").send_keys("?") }
        within_window new_window do
          expect(page).to have_current_path(%r{\Ahttps://www\.openproject\.org/docs}, url: true)
        end

        new_window.close
      end
    end
  end

  describe "context menus" do
    before do
      visit_index_page
    end

    describe "work package context menu", :js do
      let(:context_menu_label) { I18n.t("js.label_work_package_context_menu") }
      let(:subject_cell) { ".work-package-table--container tr.issue .wp-table--cell-td.subject" }

      it "focuses the first item and returns focus to the cell on Escape" do
        cell = find(subject_cell)
        cell.hover
        send_keys_without_click(cell, %i[shift alt f10])

        within(:menu, context_menu_label) do
          expect(page).to have_selector(:menuitem, I18n.t("js.button_open_details"), focused: true)
          expect(page).to have_selector(:menuitem, I18n.t("js.button_open_fullscreen"))
        end

        send_keys_without_click(page.active_element, :escape)
        expect(page).to have_no_selector(:menu, context_menu_label)
        expect(page).to have_focus_on(subject_cell)
      end
    end
  end
end
