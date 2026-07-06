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

require "support/pages/page"

module Pages
  module Projects
    class Index < ::Pages::Page
      include ::Components::Common::Filters

      def path(*)
        "/projects"
      end

      def expect_projects_listed(*projects, archived: false)
        projects.each do |project|
          displayed_name = if archived
                             "#{project.name} (Archived)"
                           else
                             project.name
                           end

          expect(page).to have_css("#project-table", text: displayed_name, normalize_ws: true)
        end
      end

      def expect_projects_not_listed(*projects)
        projects.each do |project|
          case project
          when Project
            expect(page).to have_no_css("#project-table", text: project.name)
          when String
            expect(page).to have_no_css("#project-table", text: project)
          else
            raise ArgumentError, "#{project.inspect} is not a Project or a String"
          end
        end
      end

      def expect_project_at_place(project, place)
        expect(page)
          .to have_css("#project-table .project:nth-of-type(#{place}) td.name", text: project.name)
      end

      def expect_projects_in_order(*projects)
        projects.each_with_index do |project, index|
          expect_project_at_place(project, index + 1)
        end
      end

      def expect_title(name)
        expect(page).to have_css('[data-test-selector="project-query-name"]', text: name)
      end

      def expect_sidebar_filter(filter_name, selected: false, favorited: false, visible: true)
        submenu.expect_item(filter_name, selected:, favorited:, visible:)
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
        within ".PaginationContainer" do
          expect(page).to have_css("a.Page", text: number.to_s, aria: { current: "page" })
        end
      end

      def expect_total_pages(number)
        within ".op-pagination--pages" do
          expect(page).to have_css(".Page", text: number)
          expect(page).to have_no_css(".Page", text: number + 1)
        end
      end

      def expect_page_link(text)
        within ".op-pagination--pages" do
          expect(page).to have_css("a.Page", text:)
        end
      end

      def expect_page_links(model:, current_page: 1)
        within ".PaginationContainer" do
          pagination_links = page.all("a.Page")
          expect(pagination_links.size).to be_positive

          page_number_links = pagination_links.select { |link| link["aria-label"]&.match?(/\APage \d+\z/) }

          page_number_links.each do |pagination_link|
            page_number = pagination_link.text.to_i
            uri = URI.parse(pagination_link["href"])
            expect(uri.path).to eq(path(model))
            expect(uri.query).to include("page=#{page_number}")
          end

          if current_page > 1
            previous_link = find("a[rel='prev']", visible: true)
            previous_uri = URI.parse(previous_link["href"])
            expect(previous_uri.path).to eq(path(model))
            expect(previous_uri.query).to include("page=#{current_page - 1}")
          else
            next_link = find("a[rel='next']", visible: true)
            next_uri = URI.parse(next_link["href"])
            expect(next_uri.path).to eq(path(model))
            expect(next_uri.query).to include("page=#{current_page + 1}")
          end
        end
      end

      def expect_page_sizes(model:)
        within ".op-pagination--options" do
          pagination_links = page.all("a.Page")
          expect(pagination_links.size).to be_positive

          pagination_links.each do |pagination_link|
            uri = URI.parse(pagination_link["href"])
            expect(uri.path).to eq(path(model))
          end
        end
      end

      def expect_filter_available(filter_name)
        expect(page).to have_select("add_filter_select", with_options: [filter_name])
      end

      def expect_filter_not_available(filter_name)
        expect(page).to have_no_select("add_filter_select", with_options: [filter_name])
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

      def expect_columns_in_order(*column_names)
        columns = page.find_all("#project-table th .Button-label")
        expect(column_names.map(&:upcase)).to eq(columns.map { |c| c.text.upcase })
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

      def filter_by_favorited(value)
        set_filter("favorited", "Favorite", "is", [value])
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

      def set_advanced_filter(name, human_name, human_operator = nil, values = [], send_keys: false)
        select_filter(name, human_name)

        # Classify the row before apply_operator re-renders it. Skipped when
        # there is nothing to set.
        kind = filter_kind(name) if values.any?

        within(filter_selector(name)) do
          apply_operator(name, human_operator)
        end

        return unless values.any?

        # Re-find again as apply_operator may have triggered further DOM updates
        within(filter_selector(name)) do
          if boolean_filter?(name)
            set_toggle_filter(values)
          elsif kind == :autocomplete
            set_autocomplete_filter(values)
          elsif %i[date datetime_past].include?(kind)
            wait_for_network_idle
            set_datetime_filter(name, human_operator, values, send_keys:)
          end
        end
      end

      def set_columns(*columns)
        open_configure_view

        # Assumption: there is always one item selected, the 'Name' column
        # That column can currently not be removed.
        # Serves as a safeguard
        page.find(".op-draggable-autocomplete--item", text: "Name")

        not_protected_columns = Regexp.new("^(?!#{(columns + ['Name']).join('$|')}$).*$")

        while (items = page.all(".op-draggable-autocomplete--item", text: not_protected_columns)[0]) # rubocop:disable Capybara/FindAllFirst
          items.find(".op-draggable-autocomplete--remove-item").click
        end

        remaining_columns = page.all(".op-draggable-autocomplete--item").map { |i| i.text.downcase }

        columns.each do |column|
          next if remaining_columns.include?(column.downcase)

          select_autocomplete find("ng-select.op-draggable-autocomplete--input"),
                              results_selector: "ng-dropdown-panel.op-draggable-autocomplete--input .ng-dropdown-panel-items",
                              query: column
        end

        within "dialog" do
          click_on "Apply"
        end

        wait_for_network_idle
      end

      def expect_no_config_columns(*columns)
        open_configure_view

        columns.each do |column|
          expect_no_ng_option find("ng-select.op-draggable-autocomplete--input"),
                              column,
                              results_selector: "ng-dropdown-panel.op-draggable-autocomplete--input .ng-dropdown-panel-items"
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

      def expect_no_more_menu_item(item)
        wait_for_network_idle
        page.find('[data-test-selector="project-more-dropdown-menu"]').click
        expect(page).to have_no_css(".ActionListItem", text: item, exact_text: true)
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

      def create_new_workspace(type, open_menu: false)
        label = I18n.t(:"label_#{type}")

        if open_menu
          click_on I18n.t(:button_add)
          page.find(".ActionListItem", exact_text: label).click
        else
          page.find('[data-test-selector="workspace-new-button"]', exact_text: label).click
        end
      end

      def save_query
        click_more_menu_item("Save")
        wait_for_network_idle
      end

      def save_query_via_header
        page.find('[data-test-selector="header-save-button"]').click
        wait_for_network_idle
      end

      def expect_header_save_button
        expect(page).to have_css('[data-test-selector="header-save-button"]')
      end

      def expect_no_header_save_button
        expect(page).to have_no_css('[data-test-selector="header-save-button"]')
      end

      def save_query_as(name)
        click_more_menu_item("Save as")

        fill_in_the_name(name)

        click_on "Save"
      end

      def expect_save_as_label
        expect(page).to have_text(I18n.t("lists.can_be_saved_as"))
      end

      def expect_save_label
        expect(page).to have_text(I18n.t("lists.can_be_saved"))
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

      def click_table_header_to_open_action_menu(column_name)
        find(".generic-table--sort-header #menu-#{column_name.downcase}-button").click
      end

      def sort_via_action_menu(column_name, direction:)
        raise ArgumentError, "direction should be :asc or :desc" unless %i[asc desc].include?(direction)

        find(".generic-table--sort-header a[data-test-selector='#{column_name.downcase}-sort-#{direction}']").click
      end

      def expect_no_sorting_option_in_action_menu(column_name)
        expect(page).to have_no_css("[data-test-selector='#{column_name.downcase}-sort-asc']")
        expect(page).to have_no_css("[data-test-selector='#{column_name.downcase}-sort-desc']")
      end

      def move_column_via_action_menu(column_name, direction:)
        raise ArgumentError, "direction should be :left or :right" unless %i[left right].include?(direction)

        find(".generic-table--sort-header a[data-test-selector='#{column_name.downcase}-move-col-#{direction}']").click
      end

      def remove_column_via_action_menu(column_name)
        find(".generic-table--sort-header a[data-test-selector='#{column_name.downcase}-remove-column']").click
      end

      def click_add_column_in_action_menu(column_name)
        find(".generic-table--sort-header a[data-test-selector='#{column_name.downcase}-add-column']").click
      end

      def expect_filter_option_in_action_menu(column_name)
        expect(page).to have_css("[data-test-selector='#{column_name.downcase}-filter-by']",
                                 text: I18n.t(:label_filter_by))
      end

      def expect_no_filter_option_in_action_menu(column_name)
        expect(page).to have_no_css("[data-test-selector='#{column_name.downcase}-filter-by']")
      end

      def filter_by_column_via_action_menu(column_name)
        page.find("[data-test-selector='#{column_name.downcase}-filter-by']", text: I18n.t(:label_filter_by)).click
      end

      def expect_sort_order_via_table_header(column_name, direction:)
        raise ArgumentError, "direction should be :asc or :desc" unless %i[asc desc].include?(direction)

        find(".generic-table--sort-header .#{direction} .Button-label", text: column_name.upcase)
      end

      def set_page_size(size)
        within ".op-pagination--options" do
          find("a.Page", text: size.to_s).click
        end
      end

      def expect_page_size(size)
        within ".op-pagination--options" do
          expect(page).to have_css("a.Page", text: /\A#{size}\z/, aria: { current: "page" })
        end
      end

      def go_to_page(page_number)
        within ".PaginationContainer" do
          click_link accessible_name: "Page #{page_number}"
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

      def submit_config_view_dialog
        page.find('[data-test-selector="op-project-list-configure-dialog-submit"]').click
      end

      def within_table(&)
        within "#project-table", &
      end

      def project_in_first_row(column_text_separator: "\n")
        first_row = within("#projects-table") { first(".op-project-row-component") }
        Project.find_by!(name: first_row.text.split(column_text_separator).first)
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
        %w[active member_of favorited public templated].include?(filter.to_s)
      end

      def submenu
        Components::Submenu.new
      end
    end
  end
end
