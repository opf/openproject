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

module FullCalendar
  class TimeEntryEvent < Event
    attr_accessor :time_entry

    class << self
      def from_time_entry(time_entry)
        starts_at, ends_at = start_and_end_time_from_time_entry(time_entry)

        event = new(
          id: time_entry.id,
          starts_at: starts_at,
          ends_at: ends_at,
          all_day: !time_entry.ongoing? && time_entry.start_time.blank?,
          title: "#{time_entry.project.name}: #{time_entry.entity.formatted_id} #{time_entry.entity.subject}"
        )
        event.time_entry = time_entry

        event
      end

      def start_and_end_time_from_time_entry(time_entry)
        if time_entry.ongoing?
          [
            time_entry.created_at.in_time_zone(time_entry.time_zone),
            Time.current.in_time_zone(time_entry.time_zone)
          ]
        else
          [
            time_entry.start_timestamp || time_entry.spent_on,
            time_entry.end_timestamp || time_entry.spent_on
          ]
        end
      end
    end

    def additional_attributes # rubocop:disable Metrics/AbcSize
      {
        durationEditable: time_entry.start_time.present?,
        hours: time_entry.hours_for_calculation,
        typeId: time_entry.entity.type_id,
        workPackageId: time_entry.entity.to_param,
        workPackageSubject: time_entry.entity.subject,
        projectId: time_entry.project.id,
        projectName: time_entry.project.name,
        ongoing: time_entry.ongoing?
      }
    end
  end
end
