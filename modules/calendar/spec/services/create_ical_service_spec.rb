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

require 'spec_helper'

describe Calendar::CreateIcalService, type: :model do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:work_package_with_start_date) do
    create(:work_package, project:,
                          start_date: Time.zone.today + 14.days)
  end
  let(:work_package_with_due_date) do
    create(:work_package, project:,
                          due_date: Time.zone.today + 7.days)
  end
  let(:work_package_with_start_and_due_date) do
    create(:work_package, project:,
                          start_date: Date.tomorrow, due_date: Time.zone.today + 7.days)
  end
  let(:work_package_with_due_date_and_assignee) do
    create(:work_package, project:,
                          due_date: Time.zone.today + 30.days, assigned_to: user)
  end
  let(:work_packages) do
    [
      work_package_with_due_date,
      work_package_with_start_date,
      work_package_with_start_and_due_date,
      work_package_with_due_date_and_assignee
    ]
  end
  let(:query_name) { "Query Name" }

  let(:instance) do
    described_class.new
  end

  let(:freezed_date_time) { DateTime.now }

  before do
    Timecop.freeze(freezed_date_time)
  end

  subject do
    instance.call(
      work_packages:,
      calendar_name: query_name
    )
  end

  after do
    Timecop.return
  end

  # rubocop:disable RSpec/ExampleLength
  it 'converts work_packages to an ical string which contains all required ical fields in the correct format and order' do
    expected_ical_string = <<~EOICAL.gsub("\r ", "").gsub("\r", "")
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//OpenProject GmbH//OpenProject Core Project//EN
      CALSCALE:GREGORIAN
      X-WR-CALNAME:#{query_name}
      BEGIN:VEVENT
      DTSTAMP:#{freezed_date_time.strftime('%Y%m%dT%H%M%S')}Z
      UID:#{work_package_with_due_date.id}@localhost:3000
      DTSTART;VALUE=DATE:#{work_package_with_due_date.due_date.strftime('%Y%m%d')}
      DTEND;VALUE=DATE:#{(work_package_with_due_date.due_date + 1.day).strftime('%Y%m%d')}
      DESCRIPTION:Project: #{project.name}\nType: None\nStatus: #{work_package_with_due_date.status.name}\nAssignee: \nPriority: #{work_package_with_due_date.priority.name}\n\nDescription:\n #{work_package_with_due_date.description}
      LOCATION:http://localhost:3000/work_packages/#{work_package_with_due_date.id}
      ORGANIZER:Bob Bobbit
      SUMMARY:#{work_package_with_due_date.name}
      END:VEVENT
      BEGIN:VEVENT
      DTSTAMP:#{freezed_date_time.strftime('%Y%m%dT%H%M%S')}Z
      UID:#{work_package_with_start_date.id}@localhost:3000
      DTSTART;VALUE=DATE:#{work_package_with_start_date.start_date.strftime('%Y%m%d')}
      DTEND;VALUE=DATE:#{(work_package_with_start_date.start_date + 1.day).strftime('%Y%m%d')}
      DESCRIPTION:Project: #{project.name}\nType: None\nStatus: #{work_package_with_start_date.status.name}\nAssignee: \nPriority: #{work_package_with_start_date.priority.name}\n\nDescription:\n #{work_package_with_start_date.description}
      LOCATION:http://localhost:3000/work_packages/#{work_package_with_start_date.id}
      ORGANIZER:Bob Bobbit
      SUMMARY:#{work_package_with_start_date.name}
      END:VEVENT
      BEGIN:VEVENT
      DTSTAMP:#{freezed_date_time.strftime('%Y%m%dT%H%M%S')}Z
      UID:#{work_package_with_start_and_due_date.id}@localhost:3000
      DTSTART;VALUE=DATE:#{work_package_with_start_and_due_date.start_date.strftime('%Y%m%d')}
      DTEND;VALUE=DATE:#{(work_package_with_start_and_due_date.due_date + 1.day).strftime('%Y%m%d')}
      DESCRIPTION:Project: #{project.name}\nType: None\nStatus: #{work_package_with_start_and_due_date.status.name}\nAssignee: \nPriority: #{work_package_with_start_and_due_date.priority.name}\n\nDescription:\n #{work_package_with_start_and_due_date.description}
      LOCATION:http://localhost:3000/work_packages/#{work_package_with_start_and_due_date.id}
      ORGANIZER:Bob Bobbit
      SUMMARY:#{work_package_with_start_and_due_date.name}
      END:VEVENT
      BEGIN:VEVENT
      DTSTAMP:#{freezed_date_time.strftime('%Y%m%dT%H%M%S')}Z
      UID:#{work_package_with_due_date_and_assignee.id}@localhost:3000
      DTSTART;VALUE=DATE:#{work_package_with_due_date_and_assignee.due_date.strftime('%Y%m%d')}
      DTEND;VALUE=DATE:#{(work_package_with_due_date_and_assignee.due_date + 1.day).strftime('%Y%m%d')}
      DESCRIPTION:Project: #{project.name}\nType: None\nStatus: #{work_package_with_due_date_and_assignee.status.name}\nAssignee: #{work_package_with_due_date_and_assignee.assigned_to.name}\nPriority: #{work_package_with_due_date_and_assignee.priority.name}\n\nDescription:\n #{work_package_with_due_date_and_assignee.description}
      LOCATION:http://localhost:3000/work_packages/#{work_package_with_due_date_and_assignee.id}
      ORGANIZER:Bob Bobbit
      SUMMARY:#{work_package_with_due_date_and_assignee.name}
      ATTENDEE:#{work_package_with_due_date_and_assignee.assigned_to.name}
      END:VEVENT
      END:VCALENDAR
    EOICAL

    expect(subject.result.gsub("\r\n ", "").gsub("\r", "").gsub("\\n", "\n"))
      .to eql(expected_ical_string)
  end
  # rubocop:enable RSpec/ExampleLength

  it 'is a success' do
    expect(subject)
      .to be_success
  end
end
