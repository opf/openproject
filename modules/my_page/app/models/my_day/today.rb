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
  # What the user has planned for today: their "My work" tasks due today and the meetings they take
  # part in, split into day parts. Tasks without a day part count as morning.
  class Today
    DAY_PARTS = DayPartField::DAY_PARTS
    AFTERNOON_FROM = 12
    EVENING_FROM = 17

    Section = Data.define(:day_part, :meetings, :work_packages) do
      def open_count = work_packages.count { !it.closed? }

      def empty? = meetings.empty? && work_packages.empty?
    end

    attr_reader :user, :project, :date

    def self.for(user)
      call = ProjectService.new(user).call
      new(user:, project: call.result) if call.success?
    end

    def initialize(user:, project:)
      @user = user
      @project = project
      @date = user.today
    end

    def sections
      @sections ||= DAY_PARTS.map do |day_part|
        Section.new(day_part:,
                    meetings: meetings.select { day_part_at(it.start_time) == day_part },
                    work_packages: work_packages.select { day_part_field.day_part_of(it) == day_part })
      end
    end

    def open_count = sections.sum(&:open_count)

    def current_day_part = day_part_at(Time.current)

    def now?(day_part) = current_day_part == day_part

    def meetings
      @meetings ||= Meeting
                      .visible(user)
                      .not_templated
                      .participated_by(user)
                      .preload(participants: :user)
                      .where(start_time: date.in_time_zone(user.time_zone).all_day)
                      .order(:start_time)
                      .to_a
    end

    def work_packages
      @work_packages ||= project
                           .work_packages
                           .where(due_date: date)
                           .includes(:status, :type, :project, :custom_values)
                           .order(:id)
                           .to_a
    end

    def references
      @references ||= References.for(user, work_packages)
    end

    private

    def day_part_at(time)
      hour = time.in_time_zone(user.time_zone).hour

      if hour < AFTERNOON_FROM then :morning
      elsif hour < EVENING_FROM then :afternoon
      else :evening
      end
    end

    def day_part_field
      @day_part_field ||= DayPartField.find
    end
  end
end
