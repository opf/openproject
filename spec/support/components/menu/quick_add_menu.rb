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
require_relative "dropdown"

module Components
  class QuickAddMenu < Dropdown
    def id
      "op-app-header--quick-add-menu"
    end

    def expect_visible
      expect(trigger_element).to be_present
    end

    def expect_invisible
      expect { trigger_element }.to raise_error(Capybara::ElementNotFound)
    end

    def expect_add_project(present: true)
      expect_link "Project", present:
    end

    def expect_user_invite(present: true)
      expect_link "Invite user", present:
    end

    def expect_board(present: true)
      expect_link "Board", present:
    end

    def expect_meeting(present: true)
      expect_link "Meeting", present:
    end

    def expect_document(present: true)
      expect_link "Document", present:
    end

    def open_work_package_submenu
      within_dropdown do
        page.click_button "Work package"
      end
    end

    def expect_work_package_type(*names, present: true)
      names.each do |name|
        expect_link name, present:
      end
    end

    def expect_no_work_package_types
      within_dropdown do
        expect(page).to have_no_button "Work package"
      end
    end

    def click_link(matcher)
      within_dropdown do
        page.click_link matcher
      end
    end

    def expect_link(matcher, present: true)
      within_dropdown do
        if present
          expect(page).to have_link matcher
        else
          expect(page).to have_no_link matcher
        end
      end
    end

    def trigger_element
      page.find_test_selector("quick-add-menu-button")
    end
  end
end
