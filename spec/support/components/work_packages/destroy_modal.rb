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

module Components
  module WorkPackages
    class DestroyModal
      include Capybara::DSL
      include RSpec::Matchers

      def container
        '#wp_destroy_modal'
      end

      def expect_listed(*wps)
        page.within(container) do
          if wps.length == 1
            wp = wps.first
            expect(page).to have_selector('strong', text: "#{wp.type.name} ##{wp.id} #{wp.subject}")
          else
            expect(page).to have_selector('.danger-zone--warning', text: 'Are you sure you want to delete the following work packages ?')
            wps.each do |wp|
              expect(page).to have_selector('li', text: "##{wp.id} #{wp.subject}")
            end
          end
        end
      end

      def confirm_children_deletion
        page.within(container) do
          check 'confirm-children-deletion'
        end
      end

      def confirm_deletion
        page.within(container) do
          click_button 'Confirm'
        end
      end

      def cancel_deletion
        page.within(container) do
          click_button 'Cancel'
        end
      end
    end
  end
end
