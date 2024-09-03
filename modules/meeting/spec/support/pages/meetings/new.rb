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

require_relative "base"
require_relative "show"

module Pages::Meetings
  class New < Base
    include Components::Autocompleter::NgSelectAutocompleteHelpers

    def expect_no_main_menu
      expect(page).to have_no_css "#main-menu"
    end

    def click_create
      click_on "Create"

      meeting = Meeting.last

      if meeting
        Pages::Meetings::Show.new(meeting)
      else
        self
      end
    end

    def set_type(type)
      choose type, match: :first
    end

    def set_title(text)
      fill_in "Title", with: text
    end

    def expect_project_dropdown
      find "[data-test-selector='project_id']"
    end

    def set_project(project)
      select_autocomplete find("[data-test-selector='project_id']"),
                          query: project.name,
                          results_selector: "body"
    end

    def set_start_date(date)
      find_by_id("meeting_start_date").click
      datepicker = Components::BasicDatepicker.new
      datepicker.set_date(date)
    end

    def set_start_time(time)
      input = page.find_by_id("meeting-form-start-time")
      page.execute_script("arguments[0].value = arguments[1]", input.native, time)
    end

    def set_duration(duration)
      fill_in "Duration", with: duration
    end

    def invite(user)
      check "#{user.name} invited"
    end

    def path
      polymorphic_path([:new, project, :meeting])
    end
  end
end
