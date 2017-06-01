#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'

module Pages
  class Members < Page
    include Capybara::Select2

    attr_reader :project_identifier

    def initialize(project_identifier)
      @project_identifier = project_identifier
    end

    def path
      "/projects/#{project_identifier}/members"
    end

    def open_new_member!
      click_on 'Add member'
    end

    ##
    # Adds the given user to this project.
    #
    # @param user_name [String] The full name of the user.
    # @param as [String] The role as which the user should be added.
    def add_user!(user_name, as:)
      click_on 'Add member'

      select_principal! user_name if user_name
      select_role! as if as

      click_on 'Add'
    end

    def remove_user!(user_name)
      find_user(user_name).find('a[data-method=delete]').click
    end

    def remove_group!(group_name)
      find_group(group_name).find('a[data-method=delete]').click
    end

    def has_added_user?(name, visible: true, css: "tr")
      has_text?("Added #{name} to the project") and ((not visible) or
        has_css?(css, text: user_name_to_text(name)))
    end

    def has_added_group?(name, visible: true)
      has_added_user? name, visible: visible, css: "tr.group"
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
      has_selector?(css, text: user_name_to_text(name)) &&
        (roles.nil? || has_roles?(name, roles, group: group)) &&
        (group_membership.nil? || group_membership == has_group_membership?(name))
    end

    def has_group?(name, roles: nil)
      has_user?(name, roles: roles, group: true)
    end

    def find_user(name)
      find('tr', text: user_name_to_text(name))
    end

    def find_group(name)
      find('tr.group', text: user_name_to_text(name))
    end

    def user_name_to_text(name)
      # the members table shows last name and first name separately
      # let's just look for the last name
      name.split(" ").last
    end

    def edit_user!(name, add_roles: [], remove_roles: [])
      user = find_user(name)
      user.find('a[title=Edit]').click

      Array(add_roles).each { |role| check role }
      Array(remove_roles).each { |role| uncheck role }

      click_on 'Change'
    end

    def has_group_membership?(user_name)
      user = find_user(user_name)

      user.has_selector?('a[title=Edit]') &&
        user.has_no_selector?('a[title=Delete]')
    end

    def has_roles?(user_name, roles, group: false)
      user = group ? find_group(user_name) : find_user(user_name)

      Array(roles).all? { |role| user.has_text? role }
    end

    def select_principal!(principal_name)
      if !User.current.impaired?
        select2(principal_name, css: '#s2id_member_user_ids')
      else
        find('form .principals').check principal_name
      end
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
      input = find '.select2-search-field input#s2id_autogen3'
      input.set query
    end

    def select_search_result!(value)
      find('.select2-results div', text: value).click
    end

    def has_no_search_results?
      has_text?('No matches found')
    end

    ##
    # Indicates whether the given principal has been selected as one
    # of the users to be added to the project in the 'New member' dialogue.
    def has_selected_new_principal?(name)
      has_selector? '.select2-search-choice', text: name
    end

    def select_role!(role_name)
      if !User.current.impaired?
        select = find('select#member_role_ids')
        select.select role_name
      else
        find('form .roles').check role_name
      end
    end

    def enter_principal_search!(principal_name)
      if !User.current.impaired?
        find('#s2id_member_user_ids')
          .find('.select2-choices .select2-input')
          .set(principal_name)
      else
        fill_in 'principal_search', with: principal_name
      end
    end

    def go_to_page!(number)
      find('.pagination a', text: number.to_s).click
    end
  end
end
