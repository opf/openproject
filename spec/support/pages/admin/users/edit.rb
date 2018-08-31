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
  module Admin
    module Users
      class Edit < ::Pages::Page
        attr_reader :id

        def initialize(id)
          @id = id
        end

        def path
          "/users/#{id}/edit"
        end

        def open_projects_tab!
          click_on 'tab-memberships'
        end

        def add_to_project!(project_name, as:)
          open_projects_tab!
          select_project! project_name
          Array(as).each { |role| check role }
          click_on 'Add'

          expect_project(project_name)
        end

        def remove_from_project!(name)
          open_projects_tab!
          find_project(name).find('a[data-method=delete]').click
        end

        def edit_roles!(membership, roles)
          find("#member-#{membership.id} .user-memberships--edit-button").click

          page.within("#member-#{membership.id}-roles-form") do
            page.all('.form--check-box').each do |f|
              begin
                f.set false
              rescue Selenium::WebDriver::Error::InvalidElementStateError
                # Happens if an element is disabled
              end
            end
            Array(roles).each { |role| page.check role }
            page.find('.user-memberships--edit-submit-button').click
          end
        end

        def expect_project(project_name)
          expect(page).to have_selector('tr', text: project_name, wait: 10)
        end

        def expect_no_membership(project_name)
          expect(page).to have_no_selector('tr', text: project_name)
        end

        def expect_roles(project_name, roles)
          row = page.find('tr', text: project_name, wait: 10)

          roles.each do |role|
            expect(row).to have_selector('span', text: role)
          end
        end

        def find_project(name)
          find('tr', text: name)
        end

        def has_project?(name)
          has_selector? 'tr', text: name
        end

        def select_project!(project_name)
          select(project_name, from: 'membership_project_id')
        end

        def activate!
          within '.toolbar-items' do
            click_button 'Activate'
          end
        end
      end
    end
  end
end
