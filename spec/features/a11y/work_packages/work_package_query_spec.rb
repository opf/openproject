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
require "features/work_packages/work_packages_page"

RSpec.describe "Work package index accessibility", :selenium do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:sort_ascending_selector) { ".icon-sort-ascending" }
  let(:sort_descending_selector) { ".icon-sort-descending" }

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

    def click_sort_ascending_link
      expect(page).to have_selector(sort_ascending_selector)
      element = find(sort_ascending_selector)
      element.click
    end

    def click_sort_descending_link
      expect(page).to have_selector(sort_descending_selector)
      element = find(sort_descending_selector)
      element.click
    end

    shared_examples_for "sort column" do
      it do
        expect(page).to have_selector(column_header_selector)
      end
    end

    shared_examples_for "unsorted column" do
      it_behaves_like "sort column"
    end

    shared_examples_for "ascending sorted column" do
      it_behaves_like "sort column"
    end

    shared_examples_for "descending sorted column" do
      it_behaves_like "sort column"
    end

    shared_examples_for "sortable column" do
      before { expect(page).to have_selector(column_header_selector) }

      describe "Initial sort" do
        it_behaves_like "unsorted column"
      end

      describe "descending" do
        before do
          find(column_header_link_selector).click
          click_sort_descending_link
          loading_indicator_saveguard
        end

        it_behaves_like "descending sorted column"
      end

      describe "ascending" do
        before do
          find(column_header_link_selector).click
          click_sort_ascending_link
          loading_indicator_saveguard
        end

        it_behaves_like "ascending sorted column"
      end
    end

    describe "id column" do
      let(:link_caption) { "ID" }
      let(:column_header_selector) { ".work-package-table--container th:nth-of-type(2)" }
      let(:column_header_link_selector) { column_header_selector + " a" }

      it_behaves_like "sortable column"
    end

    describe "subject column" do
      let(:link_caption) { "Subject" }
      let(:column_header_selector) { ".work-package-table--container th:nth-of-type(3)" }
      let(:column_header_link_selector) { column_header_selector + " #subject" }

      it_behaves_like "sortable column"
    end

    describe "type column" do
      let(:link_caption) { "Type" }
      let(:column_header_selector) { ".work-package-table--container th:nth-of-type(4)" }
      let(:column_header_link_selector) { column_header_selector + " a" }

      it_behaves_like "sortable column"
    end

    describe "status column" do
      let(:link_caption) { "Status" }
      let(:column_header_selector) { ".work-package-table--container th:nth-of-type(5)" }
      let(:column_header_link_selector) { column_header_selector + " a" }

      it_behaves_like "sortable column"
    end

    describe "assigned to column" do
      let(:link_caption) { "Assignee" }
      let(:column_header_selector) { ".work-package-table--container th:nth-of-type(6)" }
      let(:column_header_link_selector) { column_header_selector + " a" }

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

        find("body").native.send_keys("j")
        expect(page).to have_focus_on(first_row_selector)

        # Avoid sending keys on body since that resets focus
        page.driver.browser.switch_to.active_element.send_keys("j")
        expect(page).to have_focus_on(second_row_selector)

        page.driver.browser.switch_to.active_element.send_keys("k")
        expect(page).to have_focus_on(first_row_selector)
      end
    end

    context "help" do
      it "opens help popup with '?'" do
        expect_angular_frontend_initialized

        new_window = window_opened_by { find("body").native.send_keys("?") }
        within_window new_window do
          expect(page.current_url).to start_with "https://www.openproject.org/docs"
        end

        new_window.close
      end
    end
  end

  describe "context menus" do
    before do
      visit_index_page
    end

    shared_examples_for "context menu" do
      it "resets the context menu focus properly" do
        expect(page).to have_selector(source_link)
        element = find(source_link)
        element.hover
        element.native.send_keys(keys)

        # Expect to open and focus the menu
        expect(page).to have_focus_on(target_link) if sets_focus
        element = find(target_link)

        element.native.send_keys(:escape)
        expect(page).to have_no_selector(target_link)

        # Expect reset focus on originating element
        expect(page).to have_focus_on(source_link) if sets_focus
      end
    end

    describe "work package context menu", :js do
      it_behaves_like "context menu" do
        let(:target_link) { "#work-package-context-menu a.detailsViewMenuItem" }
        let(:source_link) { ".work-package-table--container tr.issue td.id a" }
        let(:keys) { %i[shift alt f10] }
        let(:sets_focus) { true }
      end

      it_behaves_like "context menu" do
        let(:target_link) { "#work-package-context-menu a.openFullScreenView" }
        let(:source_link) { ".work-package-table--container tr.issue td.id a" }
        let(:keys) { %i[shift alt f10] }
        let(:sets_focus) { false }
      end
    end
  end
end
