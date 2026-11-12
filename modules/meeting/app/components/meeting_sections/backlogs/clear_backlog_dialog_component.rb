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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module MeetingSections
  class Backlogs::ClearBacklogDialogComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable

    def initialize(meeting, current_occurrence:)
      super

      @meeting = meeting
      @current_occurrence = current_occurrence
    end

    private

    def heading
      if @meeting.recurring?
        I18n.t(:label_series_backlog_clear_title)
      else
        I18n.t(:label_agenda_backlog_clear_title)
      end
    end

    def description
      if @meeting.recurring?
        I18n.t(:text_series_backlog_clear_description)
      else
        I18n.t(:text_agenda_backlog_clear_description)
      end
    end
  end
end
