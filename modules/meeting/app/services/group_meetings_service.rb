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

class GroupMeetingsService
  include Redmine::I18n
  include PaginationHelper

  GROUPS = %i[today tomorrow this_week later].freeze

  def initialize(all_meetings, as_options: false, limit: nil)
    @all_meetings = all_meetings
    @as_options = as_options
    @limit = @as_options ? @all_meetings.count : limit
  end

  def call
    if @as_options
      ServiceResult.success(result: build_options)
    else
      ServiceResult.success(result: group_meetings)
    end
  end

  private

  def group_meetings # rubocop:disable Metrics/AbcSize
    next_week = Time
                  .current
                  .next_occurring(OpenProject::Internationalization::Date.beginning_of_week)
                  .beginning_of_day
    groups = Hash.new { |h, k| h[k] = [] }

    @all_meetings
      .where(start_time: ...next_week)
      .order(start_time: :asc)
      .each do |meeting|
      start_date = in_user_zone(meeting.start_time).to_date

      group_key =
        if start_date == Time.zone.today
          :today
        elsif start_date == Time.zone.tomorrow
          :tomorrow
        else
          :this_week
        end

      groups[group_key] << meeting
    end

    # Order of groups here affects group ordering in autocompleter
    groups[:later] = show_more_pagination(@all_meetings
                                            .where(start_time: next_week..)
                                            .order(start_time: :asc), limit: @limit)

    groups
  end

  # Flatten groups into autocompleter options
  def build_options
    group_meetings.flat_map do |key, meetings|
      label = I18n.t("label_meeting_index_#{key}")

      meetings.map do |meeting|
        {
          id: meeting.id,
          name: meeting.title,
          project: meeting.project.name,
          start_time: format_time(meeting.start_time, include_date: false),
          start_date: format_date(meeting.start_time),
          group_label: label,
          frequency: frequency(meeting)
        }
      end
    end
  end

  def frequency(meeting)
    meeting.recurring_meeting.human_frequency if meeting.recurring_meeting.present?
  end
end
