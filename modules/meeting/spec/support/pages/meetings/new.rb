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

require_relative './base'
require_relative './show'

module Pages::Meetings
  class New < Base
    def click_create
      click_button 'Create'

      meeting = Meeting.last

      if meeting
        Pages::Meetings::Show.new(meeting)
      else
        self
      end
    end

    def set_title(text)
      fill_in 'Title', with: text
    end

    def set_start_date(date)
      fill_in 'Start date', with: date
    end

    def set_start_time(time)
      fill_in 'Time', with: time
    end

    def set_duration(duration)
      fill_in 'Duration', with: duration
    end

    def invite(user)
      check "#{user.name} invited"
    end

    def path
      new_meeting_path(project)
    end
  end
end
