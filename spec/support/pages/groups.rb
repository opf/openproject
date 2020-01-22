#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
require 'support/components/ng_select_autocomplete_helpers'

module Pages
  class Groups < Page
    def path
      '/admin/groups'
    end

    def edit_group!(group_name)
      click_on group_name
    end

    def add_user_to_group!(user_name, group_name)
      visit_page unless current_page?

      edit_group! group_name
      group(group_name).add_user! user_name
    end

    def delete_group!(name)
      find_group(name).find('a[data-method=delete]').click
      accept_alert_dialog!
    end

    def find_group(name)
      find('tr', text: name)
    end

    def has_group?(name)
      has_selector? 'tr', text: name
    end

    def group(group_name)
      Group.new group_name
    end
  end

  class Group < Pages::Page
    include ::Components::NgSelectAutocompleteHelpers
    attr_reader :id

    def initialize(id)
      @id = id
    end

    def path
      "/admin/groups/#{id}/edit"
    end

    def open_users_tab!
      within('.content--tabs') do
        click_on 'Users'
      end
    end

    def open_projects_tab!
      within('.content--tabs') do
        click_on 'Projects'
      end
    end

    def add_to_project!(project_name, as:)
      open_projects_tab!
      select_project! project_name
      Array(as).each { |role| check role }
      click_on 'Add'
    end

    def remove_from_project!(name)
      open_projects_tab!
      find_project(name).find('a[data-method=delete]').click
    end

    def find_project(name)
      find('tr', text: name)
    end

    def has_project?(name)
      has_selector? 'tr', text: name
    end

    def select_project!(project_name)
      select(project_name, from: 'new_membership_project_id')
    end

    def add_user!(user_name)
      open_users_tab!

      container = page.find('.new-group-members--autocomplete')
      select_autocomplete container,
                          query: user_name
      click_on 'Add'
    end

    def remove_user!(user_name)
      open_users_tab!
      find_user(user_name).find('a[data-method=delete]').click
    end

    def find_user(user_name)
      find('tr', text: user_name)
    end

    def has_user?(user_name)
      has_selector? 'tr', text: user_name
    end
  end
end
