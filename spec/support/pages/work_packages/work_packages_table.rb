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
require_relative "concerns/work_package_by_button_creator"

module Pages
  class WorkPackagesTable < Page
    include ::Pages::WorkPackages::Concerns::WorkPackageByButtonCreator

    attr_reader :project

    # Initializes a new instance of the WorkPackagesTable class to drive the
    # work package table page.
    #
    # @param project [Project] (optional) The project object used to construct
    #   the URL. If unspecified or `nil` the global work packages page is used.
    def initialize(project = nil)
      @project = project
      super()
    end

    # Visits the work packages table with the specified query.
    #
    # @param query [Query] The query object.
    def visit_query(query)
      visit "#{path}?query_id=#{query.id}"
    end

    # Visits the work packages table with the specified parameters.
    #
    # @param params [String] The query parameters.
    def visit_with_params(params)
      visit "#{path}?#{params}"
    end

    # Expects the specified work packages to be listed in the table.
    #
    # @param work_packages [Array<WorkPackage>] The work package objects.
    def expect_work_package_listed(*work_packages)
      within(table_container) do
        work_packages.each do |wp|
          expect(page).to have_css(".wp-row-#{wp.id} td.subject",
                                   text: wp.subject,
                                   wait: 20)
        end
      end
    end

    # Expects the specified work package to have the specified attributes in the
    # table.
    #
    # @param work_package [WorkPackage] The work package object.
    # @param attr_value_hash [Hash] The attribute-value hash.
    def expect_work_package_with_attributes(work_package, attr_value_hash)
      within(table_container) do
        attr_value_hash.each do |column, value|
          expect(page).to have_css(
            ".wp-row-#{work_package.id} td.#{column}", text: value.to_s, wait: 20
          )
        end
      end
    end

    # Expects the sums row in the table to have the specified attributes.
    #
    # @param attr_value_hash [Hash] The attribute-value hash.
    def expect_sums_row_with_attributes(attr_value_hash)
      within(table_container) do
        attr_value_hash.each do |column, value|
          expect(page).to have_css(
            ".wp-table--sums-row div.#{column}", text: value.to_s, wait: 10
          )
        end
      end
    end

    # Expects a work package with the specified subject to be listed in the table.
    #
    # @param subject [String] The subject of the work package.
    def expect_work_package_subject(subject)
      within(table_container) do
        expect(page).to have_css("td.subject",
                                 text: subject,
                                 wait: 20)
      end
    end

    # Expects the specified number of work packages to be listed in the table.
    #
    # @param count [Integer] The expected number of work packages.
    def expect_work_package_count(count)
      within(table_container) do
        expect(page).to have_css(".wp--row", count:, wait: 20)
      end
    end

    # Updates the attributes of the specified work package.
    #
    # @param work_package [Object] The work package object.
    # @param key_value_map [Hash] The attribute-value map.
    def update_work_package_attributes(work_package, **key_value_map)
      key_value_map.each do |key, value|
        field = work_package_field(work_package, key)
        field.update(value, save: true)
      end
    end

    # Ensures that the specified work packages are not listed in the table.
    #
    # It wraps expecting the page not to have the given work packages
    # within a retry_block to ensure we do not fail when the page is
    # still reloading (causing stale references or not found errors).
    #
    # @param work_packages [Array<Object>] The work package objects.
    def ensure_work_package_not_listed!(*work_packages)
      retry_block(args: { tries: 3, base_interval: 5 }) do
        within(table_container) do
          work_packages.each do |wp|
            expect(page).to have_no_css(".wp-row-#{wp.id} td.subject", text: wp.subject)
          end
        end
      end
    end

    # Expects the work packages to be listed in the specified order.
    #
    # @param ids [Array<WorkPackage, String, Integer>] The work package IDs or
    #   objects.
    def expect_work_package_order(*ids)
      retry_block do
        rows = page.all ".work-package-table .wp--row"
        expected = ids.map { |el| el.is_a?(WorkPackage) ? el.id.to_s : el.to_s }
        found = rows.map { |el| el["data-work-package-id"] }

        raise "Order is incorrect: #{found.inspect} != #{expected.inspect}" unless found == expected
      end
    end

    # Expects no work packages to be listed in the table.
    def expect_no_work_package_listed
      within(table_container) do
        expect(page).to have_css("#empty-row-notification")
      end
    end

    # Expects the title of the table to be the specified name.
    #
    # @param name [String] The expected title.
    # @param editable [Boolean] (optional) Whether the title is expected to be
    #   editable.
    def expect_title(name, editable: true)
      if editable
        expect(page).to have_field("editable-toolbar-title", with: name, wait: 10)
      else
        expect(page)
          .to have_css(".toolbar-container", text: name, wait: 10)
      end
    end

    # Expects the specified query to be present in the select dropdown.
    #
    # @param name [String] The name of the query.
    def expect_query_in_select_dropdown(name)
      page.find(".title-container").click

      page.within('[data-test-selector="op-submenu--body"]') do
        expect(page).to have_test_selector("op-submenu--item-action", text: name)
      end
    end

    # Clicks the inline create button.
    def click_inline_create
      ##
      # When using the inline create on initial page load,
      # there is a delay on travis where inline create can be clicked.
      sleep 3

      container.find('[data-test-selector="op-wp-inline-create"]').click
      expect(container).to have_css(".wp-inline-create-row", wait: 10)
    end

    # Opens the split view for the specified work package.
    #
    # @param work_package [WorkPackage] The work package object.
    # @return [Pages::SplitWorkPackage] The split work package page object.
    def open_split_view(work_package)
      split_page = SplitWorkPackage.new(work_package, project)

      # Hover row to show split screen button
      row_element = row(work_package)
      row_element.hover

      scroll_to_and_click(row_element.find(".wp-table--details-link"))

      split_page
    end

    # Clicks on the row of the specified work package.
    #
    # @param work_package [WorkPackage] The work package object.
    def click_on_row(work_package)
      loading_indicator_saveguard
      page.driver.browser.action.click(row(work_package).native).perform
    end

    # Opens the full screen view of the specified work package by
    # double-clicking.
    #
    # @param work_package [WorkPackage] The work package object.
    # @return [Pages::FullWorkPackage] The full work package page object.
    def open_full_screen_by_doubleclick(work_package)
      loading_indicator_saveguard
      # The 'id' column should have enough space to be clicked
      click_target = row(work_package).find(".inline-edit--display-field.id")
      page.driver.browser.action.double_click(click_target.native).perform

      FullWorkPackage.new(work_package, project)
    end

    # Opens the full screen view of the specified work package by clicking on
    # the link.
    #
    # @param work_package [WorkPackage] The work package object.
    # @return [Pages::FullWorkPackage] The full work package page oobject.
    def open_full_screen_by_link(work_package)
      row(work_package).click_link(work_package.id.to_s)

      FullWorkPackage.new(work_package)
    end

    # Drags and drops a work package from one position to another.
    #
    # @param from [WorkPackage] The source work package object.
    # @param to [WorkPackage] The target work package object.
    def drag_and_drop_work_package(from:, to:)
      drag_and_drop_list(from:, to:, elements: ".wp-table--row", handler: ".wp-table--drag-and-drop-handle")
    end

    # Returns the row element for the specified work package.
    #
    # @param work_package [WorkPackage] The work package object.
    # @return [Capybara::Node::Element] The row element.
    def row(work_package)
      table_container.find(row_selector(work_package))
    end

    # Returns the row element for the work package inline creation (after
    # clicking "Create new work package").
    #
    # @return [Capybara::Node::Element] The row element.
    def creation_row
      table_container.find(".wp-inline-create-row")
    end

    # Returns the CSS selector for the row of the specified work package.
    #
    # @param elem [WorkPackage, String, Integer] The work package object or ID.
    # @return [String] The CSS selector.
    def row_selector(elem)
      id = elem.is_a?(WorkPackage) ? elem.id.to_s : elem.to_s
      ".wp-row-#{id}-table"
    end

    # Returns the edit field for the specified work package attribute.
    #
    # @param work_package [WorkPackage] The work package object.
    # @param attribute [Symbol] The attribute name.
    # @return [EditField, DateEditField] The edit field.
    def edit_field(work_package, attribute)
      work_package_field(work_package, attribute)
    end

    # Opens the context menu for the specified work package row.
    #
    # It returns a `Components::WorkPackages::ContextMenu` instance which can
    # be used to interact with the context menu.
    #
    # @param work_package [WorkPackage] The work package object.
    # @return [Components::WorkPackages::ContextMenu] The context menu object.
    def open_context_menu_for(work_package)
      expect_work_package_subject(work_package.subject)
      context_menu = Components::WorkPackages::ContextMenu.new
      context_menu.open_for work_package
      context_menu
    end

    # Clicks on the specified setting item in the page context menu.
    #
    # @param label [String] The label of the setting item.
    def click_setting_item(label)
      ::Components::WorkPackages::SettingsMenu
        .new.open_and_choose(label)
    end

    # Saves the work package as a new query with the specified name.
    #
    # @param name [String] The name of the new query.
    # @param by_title [Boolean] (optional) Whether to save through the title.
    #   If `false` it will save through the context menu..
    def save_as(name, by_title: false)
      if by_title
        title_input = find(".editable-toolbar-title--input")
        title_input.set(name)
        title_input.send_keys(:enter)
      else
        click_setting_item "Save as"
        fill_in "save-query-name", with: name
        click_button "Save"
      end

      expect_toast message: "Successful creation."
      expect_title name
    end

    # Saves the work package query.
    def save
      click_setting_item /Save$/
    end

    def table_container
      find("#content .work-packages-split-view--tabletimeline-side")
    end

    def work_package_container(work_package)
      if work_package.nil?
        creation_row
      else
        row(work_package)
      end
    end

    def progress_popover(work_package)
      Components::WorkPackages::ProgressPopover.new(container: work_package_container(work_package))
    end

    protected

    def container
      page
    end

    def work_package_field(work_package, key)
      container = work_package_container(work_package)
      case key.to_sym
      when :date, :startDate, :dueDate, :combinedDate
        DateEditField.new container, key, is_milestone: work_package.milestone?, is_table: true
      when :estimatedTime, :remainingTime
        ProgressEditField.new container, key
      else
        EditField.new container, key
      end
    end

    private

    def path
      project ? project_work_packages_path(project) : work_packages_path
    end

    def get_filter_name(label)
      retry_block do
        label_field = page.find(".advanced-filters--filter-name", text: label)
        filter_container = label_field.find(:xpath, "..")

        raise "Missing ID on Filter (Angular not ready?)" if filter_container["id"].nil?

        filter_container["id"].gsub("filter_", "")
      end
    end

    def create_page_class
      SplitWorkPackageCreate
    end
  end
end
