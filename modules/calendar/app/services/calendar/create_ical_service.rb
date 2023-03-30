#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'icalendar'

module Calendar
  class CreateIcalService < ::BaseServices::BaseCallable

    def perform(work_packages:, calendar_name: "OpenProject Calendar")
      ical_string = create_ical_string(work_packages, calendar_name)

      ServiceResult.success(result: ical_string)
    end

    protected

    def create_ical_string(work_packages, calendar_name)
      calendar = Icalendar::Calendar.new

      calendar.prodid = "-//OpenProject GmbH//OpenProject Core Project//EN"
      calendar.x_wr_calname = calendar_name

      work_packages&.each do |work_package|
        next if work_package.start_date.nil? && work_package.due_date.nil?

        event = create_event(work_package)
        event = add_attendee_value(event, work_package)

        calendar.add_event(event)
      end

      calendar.to_ical
    end

    def create_event(work_package)
      event = Icalendar::Event.new
      event.uid = event_uid_value(work_package)
      event.organizer = organizer_value(work_package)
      event.summary = summary_value(work_package)
      event.dtstart = dtstart_value(work_package)
      event.dtend = dtend_value(work_package)
      event.location = location_value(work_package)
      event.description = description_value(work_package)

      event
    end

    def event_uid_value(work_package)
      "#{work_package.id}@#{host}"
    end

    def attendee_value(work_package)
      [work_package.assigned_to&.name]
    end

    def organizer_value(work_package)
      work_package.author&.name
    end

    def summary_value(work_package)
      work_package.name
    end

    def dtstart_value(work_package)
      Icalendar::Values::Date.new(start_date(work_package))
    end

    def start_date(work_package)
      (work_package.start_date.presence || work_package.due_date)
    end

    def dtend_value(work_package)
      Icalendar::Values::Date.new(due_date(work_package))
    end

    def due_date(work_package)
      if work_package.due_date.present?
        work_package.due_date + 1.day
      else
        work_package.start_date + 1.day
      end
    end

    def location_value(work_package)
      OpenProject::StaticRouting::StaticRouter.new.url_helpers
        .work_package_url(
          id: work_package.id
        )
    end

    def host
      OpenProject::StaticRouting::UrlHelpers.host
    end

    def description_value(work_package)
      # TODO: translate keys
      project = "Project: #{work_package.project.name}"
      type = "Type: #{type_emoji(work_package)}#{work_package.type&.name}"
      status = "Status: #{work_package.status&.name}"
      assignee = "Assignee: #{work_package.assigned_to&.name}"
      priority = "Priority: #{priority_emoji(work_package)}#{work_package.priority&.name}"
      description = truncated_work_package_description_value(work_package)

      [
        project, type, status, assignee, priority, description
      ].join("\n")
    end

    def type_emoji(work_package)
      # TODO: Differentiate emoji based on type
      # "🟩"
    end

    def priority_emoji(work_package)
      # TODO: Differentiate emoji based on priority
      # "🟢"
    end

    def truncated_work_package_description_value(work_package)
      if work_package.description.present?
        "\nDescription:\n #{work_package.description&.truncate(250)}"
      end
    end

    def add_attendee_value(event, work_package)
      # event.attendee = [work_package.assigned_to&.name] # causing thunderbird error "id is null"
      event.attendee = attendee_value(work_package) if work_package.assigned_to.present?

      event
    end
  end
end
