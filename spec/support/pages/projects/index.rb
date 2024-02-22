#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require 'support/pages/page'

module Pages
  module Projects
    class Index < ::Pages::Page
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      def path
        "/projects"
      end

      def expect_listed(*users)
        rows = page.all 'td.username'
        expect(rows.map(&:text)).to eq(users.map(&:login))
      end

      def expect_projects_listed(*projects, archived: false)
        within_table do
          projects.each do |project|
            displayed_name = if archived
                               "ARCHIVED #{project.name}"
                             else
                               project.name
                             end

            expect(page).to have_text(displayed_name)
          end
        end
      end

      def expect_projects_not_listed(*projects)
        within_table do
          projects.each do |project|
            case project
            when Project
              expect(page).to have_no_text(project.name)
            when String
              expect(page).to have_no_text(project)
            else
              raise ArgumentError, "#{project.inspect} is not a Project or a String"
            end
          end
        end
      end

      def expect_title(name)
        expect(page)
          .to have_css('[data-test-selector="project-query-name"]', text: name)
      end

      def expect_sidebar_filter(filter_name, selected: false)
        within '#main-menu' do
          expect(page).to have_css(".op-sidemenu--item-action#{selected ? '.selected' : ''}", text: filter_name)
        end
      end

      def expect_no_sidebar_filter(filter_name)
        within '#main-menu' do
          expect(page).to have_no_css(".op-sidemenu--item-action", text: filter_name)
        end
      end

      def expect_current_page_number(number)
        expect(page)
          .to have_css('.op-pagination--item_current', text: number)
      end

      def expect_total_pages(number)
        expect(page)
          .to have_css('.op-pagination--item', text: number)

        expect(page)
          .to have_no_css('.op-pagination--item', text: number + 1)
      end

      def set_sidebar_filter(filter_name)
        within '#main-menu' do
          click_link text: filter_name
        end
      end

      def expect_filters_container_toggled
        expect(page).to have_css('.op-filters-form')
      end

      def expect_filters_container_hidden
        expect(page).to have_css('.op-filters-form', visible: :hidden)
      end

      def expect_filter_set(filter_name)
        expect(page).to have_css("li[filter-name='#{filter_name}']:not(.hidden)",
                                 visible: :hidden)
      end

      def expect_no_project_create_button
        expect(page).to have_no_css('[data-test-selector="project-new-button"]')
      end

      def expect_gantt_menu_entry(visible: false)
        if visible
          expect(page).to have_link('Open as Gantt view')
        else
          expect(page).to have_no_link('Open as Gantt view')
        end
      end

      def filter_by_active(value)
        set_filter('active',
                   'Active',
                   'is',
                   [value])

        click_button 'Apply'
      end

      def filter_by_public(value)
        set_filter('public',
                   'Public',
                   'is',
                   [value])

        click_button 'Apply'
      end

      def filter_by_membership(value)
        set_filter('member_of',
                   'I am member',
                   'is',
                   [value])

        click_button 'Apply'
      end

      def set_filter(name, human_name, human_operator = nil, values = [])
        select human_name, from: 'add_filter_select'
        selected_filter = page.find("li[filter-name='#{name}']")

        select(human_operator, from: 'operator') unless boolean_filter?(name)

        within(selected_filter) do
          return unless values.any?

          if name == 'name_and_identifier'
            set_name_and_identifier_filter(values)
          elsif boolean_filter?(name)
            set_toggle_filter(values)
          elsif name == 'created_at'
            select(human_operator, from: 'operator')
            set_created_at_filter(human_operator, values)
          elsif /cf_\d+/.match?(name)
            select(human_operator, from: 'operator')
            set_custom_field_filter(selected_filter, human_operator, values)
          end
        end
      end

      def remove_filter(name)
        page.find("li[filter-name='#{name}'] .filter_rem").click
      end

      def apply_filters
        within('.advanced-filters--filters') do
          click_on 'Apply'
        end
      end

      def set_toggle_filter(values)
        should_active = values.first == 'yes'
        is_active = page.has_selector? '[data-test-selector="spot-switch-handle"][data-qa-active]'

        if should_active != is_active
          page.find('[data-test-selector="spot-switch-handle"]').click
        end

        if should_active
          expect(page).to have_css('[data-test-selector="spot-switch-handle"][data-qa-active]')
        else
          expect(page).to have_css('[data-test-selector="spot-switch-handle"]:not([data-qa-active])')
        end
      end

      def set_name_and_identifier_filter(values)
        fill_in 'value', with: values.first
      end

      def set_created_at_filter(human_operator, values)
        case human_operator
        when 'on', 'less than days ago', 'more than days ago', 'days ago'
          fill_in 'value', with: values.first
        when 'between'
          fill_in 'from_value', with: values.first
          fill_in 'to_value', with: values.second
        end
      end

      def set_custom_field_filter(selected_filter, human_operator, values)
        if selected_filter[:'filter-type'] == 'list_optional'
          if values.size == 1
            value_select = find('.single-select select[name="value"]')
            value_select.select values.first
          end
        elsif selected_filter[:'filter-type'] == 'date'
          if human_operator == 'on'
            fill_in 'value', with: values.first
          end
        end
      end

      def open_filters
        retry_block do
          page.find('[data-test-selector="filter-component-toggle"]').click
          page.find_field('Add filter', visible: true)
        end
      end

      def set_columns(*columns)
        click_more_menu_item(I18n.t(:'queries.configure_view.heading'))

        # Assumption: there is always one item selected, the 'Name' column
        # That column can currently not be removed.
        # Serves as a safeguard
        page.find('.op-draggable-autocomplete--item', text: 'Name')

        protected_columns = Regexp.new("^(?!#{(columns + ['Name']).join('$|')}$).*$")

        while (item = page.all('.op-draggable-autocomplete--item', text: protected_columns)[0])
          puts item
          item.click
        end

        remaining_columns = page.all('.op-draggable-autocomplete--item').map(&:text)

        (columns - remaining_columns).each do |column|
          select_autocomplete find('.op-draggable-autocomplete--input'),
                              results_selector: '.ng-dropdown-panel-items',
                              query: column
        end

        click_on 'Apply'
      end

      def click_more_menu_item(item)
        page.find('[data-test-selector="project-more-dropdown-menu"]').click

        page.find('.ActionListItem', text: item, exact_text: true).click
      end

      def click_menu_item_of(title, project)
        activate_menu_of(project) do
          click_link title
        end
      end

      def activate_menu_of(project)
        within_row(project) do |row|
          row.hover
          menu = find('ul.project-actions')
          menu.click
          wait_for_network_idle if using_cuprite?
          expect(page).to have_css('.menu-drop-down-container')
          yield menu
        end
      end

      def navigate_to_new_project_page_from_toolbar_items
        page.find('[data-test-selector="project-new-button"]').click
      end

      def save_query(name)
        click_more_menu_item('Save')

        within '[data-test-selector="project-query-name"]' do
          fill_in 'Name', with: name
        end

        click_on 'Save'
      end

      def delete_query
        accept_confirm do
          click_more_menu_item('Delete')
        end
      end

      def sort_by(column_name)
        find('.generic-table--sort-header a', text: column_name.upcase).click
      end

      def set_page_size(size)
        find('.op-pagination--options .op-pagination--item', text: size).click
      end

      def got_to_page(page_number)
        within '.op-pagination--pages' do
          find('.op-pagination--item-link', text: page_number).click
        end
      end

      def within_table(&)
        within '#project-table', &
      end

      def within_row(project)
        row = page.find('#project-table tr', text: project.name)

        within row do
          yield row
        end
      end

      private

      def boolean_filter?(filter)
        %w[active member_of public templated].include?(filter.to_s)
      end
    end
  end
end
