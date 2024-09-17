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
  module Projects
    class Index < ::Pages::Page
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      def path
        "/projects"
      end

      def expect_listed(*users)
        rows = page.all "td.username"
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

      def expect_project_at_place(project, place)
        within_table do
          expect(page)
            .to have_css(".project:nth-of-type(#{place}) td.name", text: project.name)
        end
      end

      def expect_projects_in_order(*projects)
        projects.each_with_index do |project, index|
          expect_project_at_place(project, index + 1)
        end
      end

      def expect_title(name)
        expect(page).to have_css('[data-test-selector="project-query-name"]', text: name)
      end

      def expect_sidebar_filter(filter_name, selected: false, favored: false, visible: true)
        submenu.expect_item(filter_name, selected:, favored:, visible:)
      end

      def expect_no_sidebar_filter(filter_name)
        submenu.expect_no_item(filter_name)
      end

      def search_for_sidebar_filter(filter_name)
        submenu.search_for_item(filter_name)
      end

      def expect_no_search_results_in_sidebar
        submenu.expect_no_results_text
      end

      def set_sidebar_filter(filter_name)
        submenu.click_item(filter_name)
      end

      def expect_current_page_number(number)
        within ".op-pagination--pages" do
          expect(page).to have_css(".op-pagination--item_current", text: number)
        end
      end

      def expect_total_pages(number)
        within ".op-pagination--pages" do
          expect(page).to have_css(".op-pagination--item", text: number)
          expect(page).to have_no_css(".op-pagination--item", text: number + 1)
        end
      end

      def expect_page_link(text)
        within ".op-pagination--pages" do
          expect(page).to have_css("a.op-pagination--item-link", text:)
        end
      end

      def expect_filters_container_toggled
        expect(page).to have_css(".op-filters-form")
      end

      def expect_filters_container_hidden
        expect(page).to have_css(".op-filters-form", visible: :hidden)
      end

      def expect_filter_set(filter_name)
        if filter_name == "name_and_identifier"
          expect(page.find_by_id(filter_name).value).not_to be_empty
        else
          expect(page).to have_css("li[data-filter-name='#{filter_name}']:not(.hidden)", visible: :hidden)
        end
      end

      def expect_filter_count(count)
        expect(page).to have_css('[data-test-selector="filters-button-counter"]', text: count)
      end

      def expect_no_project_create_button
        expect(page).to have_no_css('[data-test-selector="project-new-button"]')
      end

      def expect_gantt_menu_entry(visible: false)
        if visible
          expect(page).to have_link("Open as Gantt view")
        else
          expect(page).to have_no_link("Open as Gantt view")
        end
      end

      def expect_columns(*column_names)
        column_names.each do |column_name|
          expect(page).to have_css("th", text: column_name.upcase)
        end
      end

      def expect_no_columns(*column_names)
        column_names.each do |column_name|
          expect(page).to have_no_css("th", text: column_name.upcase)
        end
      end

      def expect_notification(text)
        expect(page).to have_link(text, class: "PageHeader-action", exact: true)
      end

      def expect_no_notification(text)
        expect(page).to have_no_link(text, class: "PageHeader-action", exact: true)
      end

      def expect_menu_item(text, visible: true)
        expect(page).to have_link(text, class: "ActionListContent", exact: true, visible:)
      end

      def expect_no_menu_item(text, visible: true)
        expect(page).to have_no_link(text, class: "ActionListContent", exact: true, visible:)
      end

      def filter_by_active(value)
        set_filter("active", "Active", "is", [value])
        wait_for_reload
      end

      def filter_by_public(value)
        set_filter("public", "Public", "is", [value])
        wait_for_reload
      end

      def filter_by_favored(value)
        set_filter("favored", "Favorite", "is", [value])
        wait_for_reload
      end

      def filter_by_membership(value)
        set_filter("member_of", "I am member", "is", [value])
        wait_for_reload
      end

      def filter_by_name_and_identifier(value, send_keys: false)
        set_name_and_identifier_filter([value], send_keys:)
        wait_for_reload
      end

      def set_filter(name, human_name, human_operator = nil, values = [], send_keys: false)
        if name == "name_and_identifier"
          set_simple_filter(name, values, send_keys:)
        else
          set_advanced_filter(name, human_name, human_operator, values, send_keys:)
        end
      end

      def set_simple_filter(_name, values, send_keys: false)
        return unless values.any?

        set_name_and_identifier_filter(values, send_keys:) # This is the only one simple filter at the moment.
      end

      def set_advanced_filter(name, human_name, human_operator = nil, values = [], send_keys: false)
        select human_name, from: "add_filter_select"
        selected_filter = page.find("li[data-filter-name='#{name}']")
        select(human_operator, from: "operator") unless boolean_filter?(name)

        within(selected_filter) do
          return unless values.any?

          if boolean_filter?(name)
            set_toggle_filter(values)
          elsif name == "created_at"
            select(human_operator, from: "operator")
            set_created_at_filter(human_operator, values, send_keys:)
          elsif /cf_\d+/.match?(name)
            select(human_operator, from: "operator")
            set_custom_field_filter(selected_filter, human_operator, values)
          end
        end
      end

      def remove_filter(name)
        if name == "name_and_identifier"
          page.find_by_id("name_and_identifier").find(:xpath, "following-sibling::button").click
        else
          page.find("li[data-filter-name='#{name}'] .filter_rem").click
        end
      end

      def set_toggle_filter(values)
        should_active = values.first == "yes"
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

      def set_name_and_identifier_filter(values, send_keys: false)
        if send_keys
          find_field("name_and_identifier").send_keys values.first
        else
          fill_in "name_and_identifier", with: values.first
        end
      end

      def set_created_at_filter(human_operator, values, send_keys: false)
        case human_operator
        when "on", "less than days ago", "more than days ago", "days ago"
          if send_keys
            find_field("value").send_keys values.first
          else
            fill_in "value", with: values.first
          end
        when "between"
          if send_keys
            find_field("from_value").send_keysvalues.first
            find_field("to_value").send_keys values.second
          else
            fill_in "from_value", with: values.first
            fill_in "to_value", with: values.second
          end
        end
      end

      def set_custom_field_filter(selected_filter, human_operator, values, send_keys: false)
        if selected_filter[:"data-filter-type"] == "list_optional"
          if values.size == 1
            value_select = find('.single-select select[name="value"]')
            value_select.select values.first
          end
        elsif selected_filter[:"data-filter-type"] == "date"
          if human_operator == "on"
            if send_keys
              find_field("value").send_keys values.first
            else
              fill_in "value", with: values.first
            end
          end
        end
      end

      def open_filters
        retry_block do
          toggle_filters_section
          expect(page).to have_css(".op-filters-form.-expanded")
          page.find_field("Add filter", visible: true)
        end
      end

      def filters_toggle
        page.find('[data-test-selector="filter-component-toggle"]')
      end

      def toggle_filters_section
        filters_toggle.click
      end

      def set_columns(*columns)
        open_configure_view

        # Assumption: there is always one item selected, the 'Name' column
        # That column can currently not be removed.
        # Serves as a safeguard
        page.find(".op-draggable-autocomplete--item", text: "Name")

        not_protected_columns = Regexp.new("^(?!#{(columns + ['Name']).join('$|')}$).*$")

        while (item = page.all(".op-draggable-autocomplete--item", text: not_protected_columns)[0])
          item.find(".op-draggable-autocomplete--remove-item").click
        end

        remaining_columns = page.all(".op-draggable-autocomplete--item").map { |i| i.text.downcase }

        columns.each do |column|
          next if remaining_columns.include?(column.downcase)

          select_autocomplete find(".op-draggable-autocomplete--input"),
                              results_selector: ".ng-dropdown-panel-items",
                              query: column
        end

        within "dialog" do
          click_on "Apply"
        end
      end

      def expect_no_config_columns(*columns)
        open_configure_view

        columns.each do |column|
          expect_no_ng_option find(".op-draggable-autocomplete--input"),
                              column,
                              results_selector: ".ng-dropdown-panel-items"
        end

        within "dialog" do
          click_on "Cancel"
        end
      end

      def mark_query_favorite
        page.find('[data-test-selector="project-query-favorite"]').click
      end

      def unmark_query_favorite
        page.find('[data-test-selector="project-query-unfavorite"]').click
      end

      def click_more_menu_item(item)
        wait_for_network_idle
        page.find('[data-test-selector="project-more-dropdown-menu"]').click
        page.find(".ActionListItem", text: item, exact_text: true).click
        wait_for_network_idle
      end

      def click_menu_item_of(title, project)
        activate_menu_of(project) do
          click_on title
        end
      end

      def activate_menu_of(project)
        within_row(project) do |row|
          row.hover
          menu = find("[data-test-selector='project-list-row--action-menu']")
          menu_button = find("[data-test-selector='project-list-row--action-menu'] button")
          menu_button.click
          wait_for_network_idle
          expect(page).to have_css("[data-test-selector='project-list-row--action-menu-item']")
          yield menu
        end
      end

      def navigate_to_new_project_page_from_toolbar_items
        page.find('[data-test-selector="project-new-button"]').click
      end

      def save_query
        click_more_menu_item("Save")
      end

      def save_query_as(name)
        click_more_menu_item("Save as")

        fill_in_the_name(name)

        click_on "Save"
      end

      def expect_can_only_save_as_label
        expect(page).to have_text(I18n.t("lists.can_be_saved_as"))
      end

      def fill_in_the_name(name)
        within '[data-test-selector="project-query-name"]' do
          fill_in "Name", with: name
        end
      end

      def delete_query
        click_more_menu_item("Delete")

        within '[data-test-selector="op-project-list-delete-dialog"]' do
          click_on "Delete"
        end
      end

      def sort_by_via_table_header(column_name)
        find(".generic-table--sort-header a", text: column_name.upcase).click
      end

      def expect_sort_order_via_table_header(column_name, direction:)
        raise ArgumentError, "direction should be :asc or :desc" unless %i[asc desc].include?(direction)

        find(".generic-table--sort-header .#{direction} a", text: column_name.upcase)
      end

      def set_page_size(size)
        within ".op-pagination--options" do
          find(".op-pagination--item", text: size).click
        end
      end

      def expect_page_size(size)
        within ".op-pagination--options" do
          expect(page).to have_css(".op-pagination--item_current", text: size)
        end
      end

      def go_to_page(page_number)
        within ".op-pagination--pages" do
          find(".op-pagination--item-link", text: page_number).click
        end
      end

      def open_configure_view
        click_more_menu_item(I18n.t(:"queries.configure_view.heading"))
      end

      def switch_configure_view_tab(tab_name)
        within "tab-container" do
          find('button[role="tab"]', text: tab_name).click
        end
      end

      def expect_sort_order(column_identifier:, direction:, direction_enabled: true)
        select = find("select")
        segmented_control = find("segmented-control")

        expect(select.value).to eq(column_identifier.to_s)

        if direction.present?
          active_direction = segmented_control.find("button[aria-current='true']")["data-direction"]
          expect(active_direction).to eq(direction.to_s)
        else
          expect(segmented_control).to have_no_button("[aria-current='true']")
        end

        expect(segmented_control).to have_button(disabled: !direction_enabled, count: 2)
      end

      def expect_number_of_sort_fields(number, visible: true)
        expect(page).to have_css("[data-test-selector='sort-by-field']", count: number, visible:)
      end

      def change_sort_order(column_identifier:, direction:)
        find("select option[value='#{column_identifier}']").select_option
        find("segmented-control button[data-direction='#{direction}']").click
      end

      def remove_sort_order
        find("select option[value='']").select_option
      end

      def expect_sort_option_is_disabled(column_identifier:)
        select = find("select")

        expect(select).to have_css("option[value='#{column_identifier}']:disabled")
      end

      def expect_sort_option_not_available(column_identifier:)
        select = find("select")

        expect(select).to have_no_css("option[value='#{column_identifier}']")
      end

      def within_sort_row(index, &)
        field_component = page.all("[data-test-selector='sort-by-field']")[index]
        within(field_component, &)
      end

      def within_table(&)
        within "#project-table", &
      end

      def within_row(project)
        row = page.find("#project-#{project.id}")
        row.hover
        within row do
          yield row
        end
      end

      def open_share_dialog
        find_test_selector("toggle-share-dialog-button").click
      end

      private

      def boolean_filter?(filter)
        %w[active member_of favored public templated].include?(filter.to_s)
      end

      def submenu
        Components::Submenu.new
      end
    end
  end
end
