#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'
require 'support/work_packages/inline_edit_field'

module Pages
  class WorkPackagesTable < Page
    attr_reader :project

    def initialize(project = nil)
      @project = project
    end

    def visit_query(query)
      visit "#{path}?query_id=#{query.id}"
    end

    def expect_work_package_listed(work_package)
      within(table_container) do
        expect(page).to have_content(work_package.subject)
      end
    end

    def expect_no_work_package_listed
      within(table_container) do
        expect(page).to have_selector('#empty-row-notification')
      end
    end

    def click_inline_create
      find('.wp-inline-create--add-link').click
      expect(page).to have_selector('.wp--row.-new')
    end

    def open_split_view(work_package)
      # Hover row to show split screen button
      row_element = row(work_package)
      row_element.hover

      split_page = SplitWorkPackage.new(work_package, project)

      row_element.find('.wp-table--details-link').click

      split_page
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

    def click_on_row(work_package)
      loading_indicator_saveguard
      page.driver.browser.mouse.click(row(work_package).native)
    end

    def open_full_screen_by_doubleclick(work_package)
      loading_indicator_saveguard
      page.driver.browser.mouse.double_click(row(work_package).native)

      FullWorkPackage.new(work_package)
    end

    def open_full_screen_by_button(work_package)
      row(work_package).check(I18n.t('js.description_select_work_package',
                                     id: work_package.id))

      click_button(I18n.t('js.label_activate') + ' ' + I18n.t('js.button_show_view'))

      FullWorkPackage.new(work_package)
    end

    def open_full_screen_by_link(work_package)
      row(work_package).click_link(work_package.id)
    end

    def row(work_package)
      table_container.find("#work-package-#{work_package.id}")
    end

    def edit_field(work_package, attribute)
      context =
        if work_package.nil?
          table_container.find('.wp--row.-new')
        else
          row(work_package)
        end

      WorkPackageField.new(context, attribute)
    end

    def click_setting_item(label)
      find('#work-packages-settings-button').click
      find('#settingsDropdown .menu-item', text: label).click
    end

    def open_filter_section
      unless page.has_selector?('#work-packages-filter-toggle-button.-active')
        click_button('work-packages-filter-toggle-button')
      end
    end

    private

    def path
      project ? project_work_packages_path(project) : work_packages_path
    end

    def table_container
      find('#content .work-package-table--container')
    end

    def get_filter_name(label)
      filter_container = page
                         .find('.advanced-filters--filter-name', text: label)
                         .first(:xpath, './..')

      filter_container['id'].gsub('filter_', '')
    end
  end
end
