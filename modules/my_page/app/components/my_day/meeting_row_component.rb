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

module MyDay
  class MeetingRowComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include AvatarHelper

    SOON_MINUTES = 60

    def initialize(meeting:, user:, scheme:, lead_width:)
      super()
      @meeting = meeting
      @user = user
      @scheme = scheme
      @lead_width = lead_width
    end

    private

    attr_reader :meeting, :user, :scheme, :lead_width

    def start_time = local_time(meeting.start_time)

    def end_time = local_time(meeting.end_time)

    def duration
      OpenProject::Common::DurationComponent.new(meeting.duration, :hours, abbreviated: true).text
    end

    def local_time(time)
      helpers.format_time(time, include_date: false, time_zone: user.time_zone)
    end

    def kind
      meeting.recurring_meeting_id ? t("my_day.meeting_recurring") : t("my_day.meeting_one_time")
    end

    def starts_in
      minutes = ((meeting.start_time - Time.current) / 60).ceil
      t("my_day.starts_in", count: minutes) if minutes.between?(1, SOON_MINUTES)
    end

    def participants
      meeting.participants.filter_map(&:user)
    end

    def avatar_options(participant)
      { src: avatar_url(participant), alt: participant.name, unique_id: participant.id }
    end
  end
end
