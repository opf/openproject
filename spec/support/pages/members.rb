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

require "support/components/autocompleter/ng_select_autocomplete_helpers"
require "support/pages/page"

module Pages
  class Members < Page
    include ::Components::Autocompleter::NgSelectAutocompleteHelpers

    attr_reader :project_identifier

    def initialize(project_identifier)
      super()
      @project_identifier = project_identifier
    end

    def visit!
      super

      self
    end

    def path
      "/projects/#{project_identifier}/members"
    end

    def open_new_member!
      page.find('[data-test-selector="member-add-button"]').click
    end

    def open_filters!
      find_by_id("filter-member-button").click
    end

    def search_for_name(name)
      fill_in "name", with: name
      find(".simple-filters--controls input[type=submit]").click
    end

    def expect_menu_item(text, selected: false)
      if selected
        expect(page).to have_css(".op-submenu--item-action.selected", text:)
      else
        expect(page).to have_css(".op-submenu--item-action", text:)
      end
    end

    def click_menu_item(text)
      page.within("#menu-sidebar") do
        click_on text
      end
    end

    def in_user_row(user, &)
      page.within(".principal-#{user.id}", &)
    end

    ##
    # Adds the given user to this project.
    #
    # @param user_name [String] The full name of the user.
    # @param as [String] The role as which the user should be added.
    def add_user!(user_name, as:)
      retry_block do
        open_new_member!

        select_principal! user_name if user_name
        select_role! as if as

        click_on "Add"
      end
    end

    def remove_user!(user_name)
      click_row_action!(find_user(user_name), "Remove member")

      find_dialog("Remove member").click_on("Remove")
    end

    def remove_group!(group_name)
      click_row_action!(find_group(group_name), "Remove member")

      find_dialog("Remove member").click_on("Remove")
    end

    def click_row_action!(row, action)
      action_menu_button = row.find(:link_or_button) { _1.has_selector?("svg.octicon-kebab-horizontal") }

      action_menu_button.click

      # quick and dirty fix for popover element not recognised as visible (and then as interactible)
      # https://github.com/teamcapybara/capybara/issues/2755
      # https://github.com/SeleniumHQ/selenium/issues/13700
      anchored_position = action_menu_button.find(:xpath, "./ancestor::action-menu//anchored-position")
      anchored_position.execute_script("this.removeAttribute('popover')")

      row.click_on(action)

      anchored_position.execute_script("this.setAttribute('popover', 'auto')")
    end

    def find_dialog(title)
      find("dialog") { |d| d.find("h1", text: title) }
    end

    def has_added_user?(name, group: false)
      has_text?("Added #{name} to the project") && has_user?(name, group:)
    end

    def has_added_group?(name)
      has_added_user? name, group: true
    end

    ##
    # Checks if the members page lists the given user.
    #
    # @param name [String] The full name of the user.
    # @param roles [Array] Checks if the user has the given role.
    # @param group_membership [Boolean] True if the member is added through a group.
    #                                   Such members cannot be removed separately which
    #                                   is why there must be only an edit and no delete button.
    def has_user?(name, roles: nil, group_membership: nil, group: false)
      css = group ? "tr.group" : "tr"
      has_selector?(css, text: name, wait: 0.5) &&
        (roles.nil? || has_roles?(name, roles, group:)) &&
        (group_membership.nil? || group_membership == has_group_membership?(name))
    end

    def has_group?(name, roles: nil)
      has_user?(name, roles:, group: true)
    end

    def find_user(name)
      find("tr", text: name)
    end

    def find_mail(mail)
      find("td.email", text: mail)
    end

    def find_group(name)
      find("tr.group", text: name)
    end

    ##
    # Get contents of all cells sorted
    def contents(column, raw: false)
      nodes =
        if raw
          all("td.#{column}")
        else
          all("td.#{column} a, td.#{column} span")
        end

      nodes.map(&:text)
    end

    def edit_user!(name, add_roles: [], remove_roles: [])
      click_row_action!(find_user(name), "Manage roles")

      Array(add_roles).each { |role| check role }
      Array(remove_roles).each { |role| uncheck role }

      click_on "Change"
    end

    def has_group_membership?(user_name)
      user = find_user(user_name)

      remove_dialog_id = user.find(:link_or_button, "Remove member", visible: false)["data-show-dialog-id"]
      user.has_selector?(:link_or_button, "Manage roles", visible: false) &&
        page.find("dialog##{remove_dialog_id}", visible: false).has_no_selector?(:button, "Remove", visible: false)
    end

    def has_roles?(user_name, roles, group: false)
      user = group ? find_group(user_name) : find_user(user_name)

      Array(roles).all? { |role| user.has_text? role }
    end

    def select_principal!(principal_name)
      select_autocomplete page.find("opce-members-autocompleter"),
                          query: principal_name,
                          results_selector: ".ng-dropdown-panel-items"
    end

    ##
    # Searches for a string in the 'New Member' dialogue's principal
    # selection and selects the given entry.
    #
    # @param query What to search for in the user search field.
    # @param selection The exact result to select.
    def search_and_select_principal!(query, selection)
      search_principal! query
      select_search_result! selection
    end

    def search_principal!(query)
      search_autocomplete page.find("opce-members-autocompleter"),
                          query:,
                          results_selector: ".ng-dropdown-panel-items"
    end

    def select_search_result!(value)
      find(".ng-option", text: value).click
    end

    def has_search_result?(value)
      page.has_selector?(".ng-option", text: value)
    end

    def has_no_search_results?
      page.has_selector?(".ng-option", text: "No items found")
    end

    def sort_by(column)
      find(".generic-table--sort-header a", text: column.upcase).click
    end

    def expect_sorted_by(column, desc: false)
      page.within(".generic-table--sort-header", text: column.upcase) do
        if desc
          expect(page).to have_css(".sort.desc")
        else
          expect(page).to have_css(".sort.asc")
        end
      end
    end

    ##
    # Indicates whether the given principal has been selected as one
    # of the users to be added to the project in the 'New member' dialogue.
    def has_selected_new_principal?(name)
      has_selector? ".ng-value", text: name
    end

    def select_role!(role_name)
      find("select#member_role_ids").select role_name
    end

    def expect_role(role_name, present: true)
      expect(page).to have_conditional_selector(present, "#member_role_ids option", text: role_name)
    end

    def go_to_page!(number)
      find(".op-pagination--pages a", text: number.to_s).click
    end
  end
end
