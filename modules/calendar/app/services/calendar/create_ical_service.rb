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
require 'rails-html-sanitizer'

module Calendar
  class CreateICalService < ::BaseServices::BaseCallable
    include TextFormattingHelper

    def perform(work_packages:, calendar_name: "OpenProject Calendar")
      ical_string = create_ical_string(work_packages, calendar_name)

      ServiceResult.success(result: ical_string)
    end

    protected

    def create_ical_string(work_packages, calendar_name)
      calendar = Icalendar::Calendar.new

      calendar.prodid = "-//OpenProject GmbH//OpenProject Core Project//EN"
      calendar.x_wr_calname = calendar_name

      work_packages.each do |work_package|
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
      map = map_description_values(work_package)

      [
        map[:project], map[:type], map[:status],
        map[:assignee], map[:priority], map[:description]
      ].join("\n")
    end

    def map_description_values(work_package)
      map = {}
      map[:project] = translated_project_name(work_package)
      map[:type] = translated_type_name(work_package)
      map[:status] = translated_status_name(work_package)
      map[:assignee] = translated_assigne_name(work_package)
      map[:priority] = translated_priority_name(work_package)
      map[:description] = truncated_work_package_description_value(work_package)

      map
    end

    def translated_project_name(work_package)
      "#{I18n::t('activerecord.models.project')}: #{work_package.project.name}"
    end

    def translated_type_name(work_package)
      "#{I18n::t('activerecord.models.type')}: #{work_package.type&.name}"
    end

    def translated_status_name(work_package)
      "#{I18n::t('attributes.status')}: #{work_package.status&.name}"
    end

    def translated_assigne_name(work_package)
      "#{I18n::t('attributes.assignee')}: #{work_package.assigned_to&.name}"
    end

    def translated_priority_name(work_package)
      "#{I18n::t('activerecord.attributes.work_package.priority')}: #{work_package.priority&.name}"
    end

    def translated_description_name
      I18n::t("attributes.description")
    end

    def truncated_work_package_description_value(work_package)
      if work_package.description.present?
        stripped_text = truncate_formatted_text(work_package.description.to_s, length: 250)
        "\n#{translated_description_name}:\n #{stripped_text}"
      end
    end

    def add_attendee_value(event, work_package)
      # event.attendee = [work_package.assigned_to&.name] # causing thunderbird error "id is null"
      event.attendee = attendee_value(work_package) if work_package.assigned_to.present?

      event
    end

    # override from text_formatting_helper
    # didn't work in this context -> got error "undefined method `full_sanitizer`"
    # furthermore the replacement of \n with <br> is not desired in the context of iCalendar files
    def truncate_formatted_text(text, length: 120)
      # rubocop:disable Rails/OutputSafety
      stripped_text = sanitizer_instance.sanitize(format_text(text)).html_safe

      if length
        truncate_multiline(stripped_text, length)
      else
        stripped_text
      end
        .strip
        .html_safe
      # rubocop:enable Rails/OutputSafety
    end

    # override from text_formatting_helper
    # the original method was statically truncating at 120 characters
    def truncate_multiline(string, length)
      if string.to_s =~ /\A(.{#{length}}).*?$/m
        "#{$1}..."
      else
        string
      end
    end

    # got error "undefined method `full_sanitizer`" without this when calling `strip_tags`
    def sanitizer_instance
      @sanitizer_instance ||= Rails::Html::FullSanitizer.new
    end
  end
end
