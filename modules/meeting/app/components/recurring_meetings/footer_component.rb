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

module RecurringMeetings
  class FooterComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, project:, count:, direction:, max_count:)
      super

      @meeting = meeting
      @project = project
      @current_count = count
      @direction = direction.to_sym
      @max_count = max_count
    end

    def next_count
      @current_count + PaginationHelper::SHOW_MORE_DEFAULT_INCREMENT
    end

    def label
      if @direction == :past || !@meeting.end_after_never?
        countable_label
      else
        # If it never ends, don't try to count it
        endless_label
      end
    end

    def countable_label
      count = @max_count - @current_count
      if @direction == :past
        I18n.t("label_recurring_meeting_more_past", count:)
      else
        I18n.t("label_recurring_meeting_more", count:, schedule: @meeting.full_schedule_in_words)
      end
    end

    def endless_label
      I18n.t("label_recurring_meeting_no_end_date", schedule: @meeting.full_schedule_in_words)
    end
  end
end
