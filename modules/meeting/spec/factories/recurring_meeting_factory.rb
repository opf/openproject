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

FactoryBot.define do
  factory :recurring_meeting, class: "RecurringMeeting" do |m|
    author factory: :user
    project
    start_time { Date.tomorrow + 10.hours }
    current_schedule_start { start_time }
    end_date { 1.year.from_now }
    duration { 1.0 }
    frequency { "weekly" }
    monthly_day { nil }
    monthly_ordinal { nil }
    monthly_weekday { nil }
    interval { 1 }
    iterations { 10 }
    end_after { "specific_date" }
    time_zone { "UTC" }

    location { "https://some-url.com" }
    m.sequence(:title) { |n| "Meeting series #{n}" }

    after(:create) do |recurring_meeting, evaluator|
      project = evaluator.project
      recurring_meeting.project = project

      # create template
      template = create(:meeting_template,
                        :author_participates,
                        start_time: recurring_meeting.start_time,
                        title: recurring_meeting.title,
                        location: recurring_meeting.location,
                        author: recurring_meeting.author,
                        duration: recurring_meeting.duration,
                        recurring_meeting:,
                        project:)

      # create agenda item
      create(:meeting_agenda_item, meeting: template, title: "My template item")
    end
  end
end
