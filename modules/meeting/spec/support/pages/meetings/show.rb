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

module Pages::Meetings
  class Show < Base
    attr_accessor :meeting

    def initialize(meeting)
      self.meeting = meeting
    end

    def expect_no_invited
      expect(page)
        .to have_content("#{Meeting.human_attribute_name(:participants_invited)}: -")
    end

    def expect_no_attended
      expect(page)
        .to have_content("#{Meeting.human_attribute_name(:participants_attended)}: -")
    end

    def expect_invited(*users)
      users.each do |user|
        within(meeting_details_container) do
          expect(page)
            .to have_link(user.name)
        end
      end
    end

    def expect_uninvited(*users)
      users.each do |user|
        within(meeting_details_container) do
          expect(page)
            .to have_no_link(user.name)
        end
      end
    end

    def expect_date_time(expected)
      expect(page)
        .to have_content("Start time: #{expected}")
    end

    def expect_link_to_location(location)
      within(meeting_details_container) do
        expect(page).to have_link location
      end
    end

    def expect_plaintext_location(location)
      within(meeting_details_container) do
        expect(page).to have_no_link location
        expect(page).to have_text(location)
      end
    end

    def meeting_details_container
      find(".meeting.details")
    end

    def click_edit
      within ".meeting--main-toolbar .toolbar-items" do
        click_on "Edit"
      end
    end

    def path
      meeting_path(meeting)
    end
  end
end
