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

module ResourceAllocations
  module ScheduleSummary
    extend ActiveSupport::Concern

    OVERBOOKING_SCOPE = "resource_management.allocate_resource_dialog.overbooking"
    CARD_SCOPE = "resource_management.user_card_list.working_hours"

    def schedule_sentence(schedules, compact: false)
      first, *rest = schedules

      segments = [schedule_segment(first, compact:)]
      rest.each { |schedule| segments << schedule_change_segment(schedule, compact:) }

      sentence = segments.join(" ")
      compact ? sentence : t("#{OVERBOOKING_SCOPE}.schedule_note", schedule: sentence)
    end

    private

    def schedule_change_segment(schedule, compact:)
      key = compact ? "#{CARD_SCOPE}.schedule_change_compact" : "#{OVERBOOKING_SCOPE}.schedule_change"
      t(key,
        date: helpers.format_date(schedule.valid_from - 1),
        schedule: schedule_segment(schedule, compact:))
    end

    def schedule_segment(schedule, compact:)
      summary = schedule.working_days_summary
      return summary if schedule.availability_factor >= 100

      key = compact ? "#{CARD_SCOPE}.schedule_availability_compact" : "#{OVERBOOKING_SCOPE}.schedule_availability"
      t(key, schedule: summary, factor: schedule.availability_factor)
    end
  end
end
