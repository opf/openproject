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
  class CreateICalService < ::BaseServices::BaseCallable
    include ActionView::Helpers::SanitizeHelper
    include TextFormattingHelper

    def perform(work_packages:, calendar_name:)
      ical_string = create_ical_string(work_packages, calendar_name)

      ServiceResult.success(result: ical_string)
    end

    protected

    def create_ical_string(work_packages, calendar_name)
      calendar = Icalendar::Calendar.new

      calendar.prodid = "-//OpenProject GmbH//OpenProject Core Project//EN"
      calendar.refresh_interval = "PT1H"
      calendar.x_wr_calname = calendar_name

      work_packages.each do |work_package|
        event = Icalendar::Event.new
        event = add_values_to_event(event, work_package)

        calendar.add_event(event)
      end

      calendar.to_ical
    end

    def add_values_to_event(event, work_package)
      %i[
        uid
        summary
        dtstamp
        dtstart
        dtend
        location
        description
      ].each do |value|
        event.send(:"#{value}=", send(:"#{value}_value", work_package))
      end

      event
    end

    def uid_value(work_package)
      "#{work_package.id}@#{host}"
    end

    def summary_value(work_package)
      work_package.name
    end

    def dtstamp_value(work_package)
      # https://datatracker.ietf.org/doc/html/rfc5545#section-3.8.7.2
      Icalendar::Values::DateTime.new(work_package.updated_at, "tzid" => "UTC")
    end

    def dtstart_value(work_package)
      Icalendar::Values::Date.new(start_date(work_package))
    end

    def start_date(work_package)
      work_package.start_date.presence || work_package.due_date
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
      %i[
        project
        type
        status
        assigned_to
        author
        priority
      ].map do |attribute|
        translated_attribute_name_and_value(work_package, attribute)
      end
      .push(truncated_work_package_description_value(work_package))
      .join("\n")
    end

    def translated_attribute_name_and_value(work_package, attribute)
      "#{WorkPackage.human_attribute_name(attribute)}: #{work_package.public_send(attribute)&.name}"
    end

    def truncated_work_package_description_value(work_package)
      return if work_package.description.blank?

      stripped_text = truncate_formatted_text(
        work_package.description.to_s,
        length: 250,
        replace_newlines: false
      )

      "\n#{WorkPackage.human_attribute_name(:description)}:\n#{stripped_text}"
    end
  end
end
