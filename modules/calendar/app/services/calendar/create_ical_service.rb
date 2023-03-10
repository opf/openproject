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
    include OpenProject::StaticRouting::UrlHelpers
    
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

        calendar.add_event(event)
      end

      calendar.to_ical
    end

    def create_event(work_package)
      event = Icalendar::Event.new
      event.uid = "#{work_package.id}@#{host}"
      # event.attendee = [work_package.assigned_to&.name] # causing thunderbird error "id is null"
      event.attendee = [work_package.assigned_to&.name] if work_package.assigned_to.present?
      event.organizer = work_package.author&.name
      event.summary = work_package.name
      event.dtstart = Icalendar::Values::Date.new(start_date(work_package))
      event.dtend = Icalendar::Values::Date.new(due_date(work_package))
      event.location = work_package_url(work_package)
      event.description = description_value(work_package)

      event
    end
    
    def start_date(work_package)
      if work_package.start_date.present?
        work_package.start_date
      else
        work_package.due_date
      end
    end
    
    def due_date(work_package)
      if work_package.due_date.present?
        work_package.due_date + 1.day
      else
        work_package.start_date + 1.day
      end
    end

    def work_package_url(work_package)
      url_for(
        controller: :work_packages,
        action: :show,
        id: work_package.id,
        only_path: false,
        protocol: protocol,
        host: host
      )
    end

    # implementation taken from application_mailer
    def host
      if OpenProject::Configuration.rails_relative_url_root.blank?
        Setting.host_name
      else
        Setting.host_name.to_s.gsub(%r{/.*\z}, '')
      end
    end

    # implementation taken from application_mailer
    def protocol
      Setting.protocol
    end

    # # url_for wants to access the controller method, which we do not have in our service class.
    # # see: http://stackoverflow.com/questions/3659455/is-there-a-new-syntax-for-url-for-in-rails-3
    # def controller
    #   nil
    # end

    def description_value(work_package)
      # TODO: translate keys
      project = "Project: #{work_package.project.name}"
      type = "Type: #{type_emoji(work_package)}#{work_package.type&.name}"
      status = "Status: #{work_package.status&.name}"
      assignee = "Assignee: #{work_package.assigned_to&.name}"
      priority = "Priority: #{priority_emoji(work_package)}#{work_package.priority&.name}"
      unless work_package.description.blank?
        description = "\nDescription:\n #{work_package.description&.truncate(250)}"
      end

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

  end
end
