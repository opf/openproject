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

require "support/pages/page"

module Pages
  class Calendar < ::Pages::Page
    include ::Components::Autocompleter::NgSelectAutocompleteHelpers

    attr_reader :project,
                :filters,
                :query

    def initialize(project, query = nil)
      super()

      @project = project
      @filters = ::Components::WorkPackages::Filters.new
      @query = query
    end

    def path
      project_calendar_path(project, id: query&.id || "new")
    end

    def add_item(start_date, end_date)
      start_container = date_container start_date
      end_container = date_container end_date

      drag_n_drop_element(from: start_container, to: end_container)

      ::Pages::SplitWorkPackageCreate.new project:
    end

    def resize_date(work_package, date, end_date: true)
      retry_block do
        wp_strip = event(work_package)

        page
          .driver
          .browser
          .action
          .move_to(wp_strip.native)
          .perform

        selector = end_date ? ".fc-event-resizer-end" : ".fc-event-resizer-start"
        resizer = wp_strip.find(selector)
        end_container = date_container date

        drag_n_drop_element(from: resizer, to: end_container)
      end
    end

    def drag_event(work_package, target)
      start_container = event(work_package)
      end_container = date_container target

      drag_n_drop_element(from: start_container, to: end_container)
    end

    def date_container(date)
      str = date.respond_to?(:iso8601) ? date.iso8601 : date.to_s
      page.find(".fc-day[data-date='#{str}'] .fc-daygrid-day-frame")
    end

    def expect_title(title = "Unnamed calendar")
      expect(page).to have_css ".editable-toolbar-title--fixed", text: title
    end

    def expect_event(work_package, present: true)
      expect(page).to have_conditional_selector(present, ".fc-event", text: work_package.subject, wait: 10)
    end

    def open_split_view(work_package)
      page
        .find(".fc-event", text: work_package.subject)
        .click

      ::Pages::SplitWorkPackage.new(work_package, project)
    end

    def event(work_package)
      page.find(".fc-event", text: work_package.subject)
    end

    def expect_wp_not_resizable(work_package)
      expect(page).to have_css(".fc-event:not(.fc-event-resizable)", text: work_package.subject)
    end

    def expect_wp_not_draggable(work_package)
      expect(page).to have_css(".fc-event:not(.fc-event-draggable)", text: work_package.subject)
    end

    def set_title(title)
      fill_in "Title", with: title
    end

    def set_project(project)
      select_autocomplete(find('[data-test-selector="project_id"]'),
                          query: project,
                          results_selector: "body",
                          wait_for_fetched_options: false)
    end

    def set_public
      check "Public"
    end

    def set_favoured
      check "Favorite"
    end

    def click_on_submit
      click_on "Create"
    end

    def click_on_create_button
      page.find_test_selector("add-calendar-button").click
    end

    def click_on_cancel_button
      click_on "Cancel"
    end

    def expect_create_button
      expect(page).to have_test_selector "add-calendar-button"
    end

    def expect_no_create_button
      expect(page).not_to have_test_selector "add-calendar-button"
    end

    def expect_delete_button(query)
      expect(page).to have_test_selector "calendar-remove-#{query.id}"
    end

    def expect_no_delete_button(query)
      expect(page).not_to have_test_selector "calendar-remove-#{query.id}"
    end

    def expect_no_views_visible
      expect(page).to have_text "There is currently nothing to display."
    end

    def expect_view_visible(query)
      expect(page).to have_css "td", text: query.name
    end

    def expect_view_not_visible(query)
      expect(page).to have_no_css "td", text: query.name
    end

    def expect_views_listed_in_order(*queries)
      within ".generic-table tbody" do
        listed_view_names = all("tr td.name").map(&:text)

        expect(listed_view_names).to eq(queries.map(&:name))
      end
    end
  end
end
