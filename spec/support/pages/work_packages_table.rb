#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'

module Pages
  class WorkPackagesTable < Page
    attr_reader :project

    def initialize(project = nil)
      @project = project
    end

    def visit_query(query)
      visit "#{path}?query_id=#{query.id}"
    end

    def visit_with_params(params)
      visit "#{path}?#{params}"
    end

    def expect_work_package_listed(*work_packages)
      within(table_container) do
        work_packages.each do |wp|
          expect(page).to have_selector(".wp-row-#{wp.id} td.subject",
                                        text: wp.subject,
                                        wait: 20)
        end
      end
    end

    def expect_work_package_subject(subject)
      within(table_container) do
        expect(page).to have_selector("td.subject",
                                      text: subject,
                                      wait: 20)
      end
    end

    def expect_work_package_count(n)
      within(table_container) do
        expect(page).to have_selector(".wp--row", count: n, wait: 20)
      end
    end

    def expect_work_package_not_listed(*work_packages, wait: 3)
      within(table_container) do
        work_packages.each do |wp|
          expect(page).to have_no_selector(".wp-row-#{wp.id} td.subject",
                                           text: wp.subject,
                                           wait: wait)
        end
      end
    end

    def expect_work_package_order(*ids)
      rows = page.all '.wp-table--row'
      expect(rows.map { |el| el['data-work-package-id'] }).to match_array(ids.map(&:to_s))
    end

    def expect_no_work_package_listed
      within(table_container) do
        expect(page).to have_selector('#empty-row-notification')
      end
    end

    def expect_title(name, editable: true)
      if editable
        expect(page).to have_field('wp-query-selectable-title', with: name, wait: 10)
      else
        expect(page)
          .to have_selector('.toolbar-container', text: name, wait: 10)
      end
    end

    def expect_query_in_select_dropdown(name)
      page.find('.title-container').click

      page.within('#querySelectDropdown') do
        expect(page).to have_selector('.ui-menu-item', text: name)
      end
    end

    def click_inline_create
      ##
      # When using the inline create on initial page load,
      # there is a delay on travis where inline create can be clicked.
      sleep 3

      find('.wp-inline-create--add-link').click
      expect(page).to have_selector('.wp-inline-create-row', wait: 10)
    end

    def create_wp_split_screen(type)
      click_wp_create_button

      find('#types-context-menu .menu-item', text: type, wait: 10).click

      SplitWorkPackageCreate.new(project: project)
    end

    def click_wp_create_button
      find('.add-work-package:not([disabled])', text: 'Create').click
    end

    def expect_type_available_for_create(type)
      click_wp_create_button

      expect(page)
        .to have_selector('#types-context-menu .menu-item', text: type.name)
    end

    def expect_type_not_available_for_create(type)
      click_wp_create_button

      expect(page)
        .to have_no_selector('#types-context-menu .menu-item', text: type.name)
    end

    def open_split_view(work_package)
      split_page = SplitWorkPackage.new(work_package, project)

      # Hover row to show split screen button
      row_element = row(work_package)
      row_element.hover

      scroll_to_and_click(row_element.find('.wp-table--details-link'))

      split_page
    end

    def click_on_row(work_package)
      loading_indicator_saveguard
      page.driver.browser.action.click(row(work_package).native).perform
    end

    def add_filter(label, operator, value)
      open_filter_section

      select(label, from: 'Add filter:')

      filter_name = get_filter_name(label)

      select(operator, from: "operators-#{filter_name}") if operator
      select(value, from: "values-#{filter_name}") if value
    end

    def expect_filter(label, operator, value)
      open_filter_section

      filter_name = get_filter_name(label)

      expect(page).to have_select("operators-#{filter_name}", selected: operator) if operator
      expect(page).to have_select("values-#{filter_name}", selected: value) if value
    end

    def open_full_screen_by_doubleclick(work_package)
      loading_indicator_saveguard
      # The 'id' column should have enough space to be clicked
      click_target = row(work_package).find('.wp-table--cell-span.id')
      page.driver.browser.action.double_click(click_target.native).perform

      FullWorkPackage.new(work_package, project)
    end

    def open_full_screen_by_link(work_package)
      row(work_package).click_link(work_package.id)

      FullWorkPackage.new(work_package)
    end

    def row(work_package)
      table_container.find(row_selector(work_package))
    end

    def row_selector(work_package)
      ".wp-row-#{work_package.id}-table"
    end

    def edit_field(work_package, attribute)
      context =
        if work_package.nil?
          table_container.find('.wp-inline-create-row')
        else
          row(work_package)
        end

      ::WorkPackageField.new(context, attribute)
    end

    def click_setting_item(label)
      ::Components::WorkPackages::SettingsMenu
        .new.open_and_choose(label)
    end

    def save_as(name)
      click_setting_item 'Save as'

      fill_in 'save-query-name', with: name

      click_button 'Save'

      expect_notification message: 'Successful creation.'
      expect_title name
    end

    def save
      click_setting_item /Save$/
    end

    def open_filter_section
      unless page.has_selector?('#work-packages-filter-toggle-button.-active')
        click_button('work-packages-filter-toggle-button')
      end
    end

    def table_container
      find('#content .work-packages-split-view--tabletimeline-side')
    end

    def work_package_row_selector(work_package)
      ".wp-row-#{work_package.id}"
    end

    private

    def path
      project ? project_work_packages_path(project) : work_packages_path
    end

    def get_filter_name(label)
      retry_block do
        label_field = page.find('.advanced-filters--filter-name', text: label)
        filter_container = label_field.find(:xpath, '..')

        raise 'Missing ID on Filter (Angular not ready?)' if filter_container['id'].nil?
        filter_container['id'].gsub('filter_', '')
      end
    end
  end
end
