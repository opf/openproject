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

require "icalendar"

module Calendar
  # Exports work packages as iCalendar VTODO components instead of VEVENTs.
  #
  # Reuses the event exporter's attribute formatting (UID, SUMMARY, DESCRIPTION,
  # LOCATION, DTSTAMP) but emits the work package's actual start and due dates:
  #
  #   * DUE is the work package's due date (not OpenProject's exclusive DTEND)
  #   * DTSTART is the work package's start date
  #
  # Passing dates=due omits DTSTART when a DUE is present. Thunderbird draws a
  # task bar from DTSTART to DUE, so the due-only mode keeps the calendar to one
  # task per due date while still preserving start-only work packages.
  class CreateVtodoService < CreateICalService
    PRIORITY_MAP = {
      "Immediate" => 1,
      "Urgent" => 1,
      "High" => 3,
      "Normal" => 5,
      "Low" => 7
    }.freeze

    protected

    def create_ical_string(work_packages, calendar_name)
      calendar = Icalendar::Calendar.new

      calendar.prodid = "-//OpenProject GmbH//OpenProject Core Project//EN"
      calendar.refresh_interval = "PT1H"
      calendar.x_wr_calname = calendar_name

      work_packages.each do |work_package|
        todo = Icalendar::Todo.new

        todo.uid = uid_value(work_package)
        todo.summary = summary_value(work_package)
        todo.dtstamp = dtstamp_value(work_package)
        todo.description = description_value(work_package)
        todo.location = location_value(work_package)
        todo.status = status_value(work_package)

        priority = priority_value(work_package)
        todo.priority = priority if priority

        add_dates(todo, work_package)

        calendar.add_todo(todo)
      end

      calendar.to_ical
    end

    def add_dates(todo, work_package)
      if work_package.due_date.present?
        todo.due = Icalendar::Values::Date.new(work_package.due_date)

        if work_package.start_date.present? && !due_only?
          todo.dtstart = Icalendar::Values::Date.new(work_package.start_date)
        end
      elsif work_package.start_date.present?
        todo.dtstart = Icalendar::Values::Date.new(work_package.start_date)
      end
    end

    def due_only?
      params[:dates].to_s == "due"
    end

    def status_value(work_package)
      status = work_package.status
      return "CANCELLED" if status.name&.casecmp?("Rejected")

      if status.respond_to?(:category)
        case status.category
        when "closed"
          "COMPLETED"
        when "in_progress"
          "IN-PROCESS"
        else
          "NEEDS-ACTION"
        end
      elsif status.respond_to?(:is_closed?)
        status.is_closed? ? "COMPLETED" : "NEEDS-ACTION"
      else
        "NEEDS-ACTION"
      end
    end

    def priority_value(work_package)
      PRIORITY_MAP[work_package.priority&.name]
    end
  end
end
