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

require "spec_helper"

RSpec.describe Calendar::CreateICalService, type: :model do
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
                          due_date: Time.zone.today + 60.days, assigned_to: user)
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

  let(:frozen_date_time) { DateTime.now }

  let(:formatted_result) do
    subject.result.gsub("\r\n ", "").delete("\r").gsub("\\n", "\n")
  end

  before do
    Timecop.freeze(frozen_date_time)
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
  it "converts work_packages to an ical string which contains all required ical fields in the correct format and order" do
    expected_ical_string = <<~EOICAL.gsub("\r ", "").delete("\r")
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//OpenProject GmbH//OpenProject Core Project//EN
      CALSCALE:GREGORIAN
      REFRESH-INTERVAL;VALUE=DURATION:PT1H
      X-WR-CALNAME:#{query_name}
      BEGIN:VEVENT
      DTSTAMP:#{work_package_with_due_date.updated_at.utc.strftime('%Y%m%dT%H%M%SZ')}
      UID:#{work_package_with_due_date.id}@localhost:3000
      DTSTART;VALUE=DATE:#{work_package_with_due_date.due_date.strftime('%Y%m%d')}
      DTEND;VALUE=DATE:#{(work_package_with_due_date.due_date + 1.day).strftime('%Y%m%d')}
      DESCRIPTION:Project: #{project.name}\nType: None\nStatus: #{work_package_with_due_date.status.name}\nAssignee: \nAuthor: #{work_package_with_due_date.author.name}\nPriority: #{work_package_with_due_date.priority.name}\n\nDescription:\n#{work_package_with_due_date.description}
      LOCATION:http://localhost:3000/work_packages/#{work_package_with_due_date.id}
      SUMMARY:#{work_package_with_due_date.name}
      END:VEVENT
      BEGIN:VEVENT
      DTSTAMP:#{work_package_with_start_date.updated_at.strftime('%Y%m%dT%H%M%SZ')}
      UID:#{work_package_with_start_date.id}@localhost:3000
      DTSTART;VALUE=DATE:#{work_package_with_start_date.start_date.strftime('%Y%m%d')}
      DTEND;VALUE=DATE:#{(work_package_with_start_date.start_date + 1.day).strftime('%Y%m%d')}
      DESCRIPTION:Project: #{project.name}\nType: None\nStatus: #{work_package_with_start_date.status.name}\nAssignee: \nAuthor: #{work_package_with_start_date.author.name}\nPriority: #{work_package_with_start_date.priority.name}\n\nDescription:\n#{work_package_with_start_date.description}
      LOCATION:http://localhost:3000/work_packages/#{work_package_with_start_date.id}
      SUMMARY:#{work_package_with_start_date.name}
      END:VEVENT
      BEGIN:VEVENT
      DTSTAMP:#{work_package_with_start_and_due_date.updated_at.strftime('%Y%m%dT%H%M%SZ')}
      UID:#{work_package_with_start_and_due_date.id}@localhost:3000
      DTSTART;VALUE=DATE:#{work_package_with_start_and_due_date.start_date.strftime('%Y%m%d')}
      DTEND;VALUE=DATE:#{(work_package_with_start_and_due_date.due_date + 1.day).strftime('%Y%m%d')}
      DESCRIPTION:Project: #{project.name}\nType: None\nStatus: #{work_package_with_start_and_due_date.status.name}\nAssignee: \nAuthor: #{work_package_with_start_and_due_date.author.name}\nPriority: #{work_package_with_start_and_due_date.priority.name}\n\nDescription:\n#{work_package_with_start_and_due_date.description}
      LOCATION:http://localhost:3000/work_packages/#{work_package_with_start_and_due_date.id}
      SUMMARY:#{work_package_with_start_and_due_date.name}
      END:VEVENT
      BEGIN:VEVENT
      DTSTAMP:#{work_package_with_due_date_and_assignee.updated_at.strftime('%Y%m%dT%H%M%SZ')}
      UID:#{work_package_with_due_date_and_assignee.id}@localhost:3000
      DTSTART;VALUE=DATE:#{work_package_with_due_date_and_assignee.due_date.strftime('%Y%m%d')}
      DTEND;VALUE=DATE:#{(work_package_with_due_date_and_assignee.due_date + 1.day).strftime('%Y%m%d')}
      DESCRIPTION:Project: #{project.name}\nType: None\nStatus: #{work_package_with_due_date_and_assignee.status.name}\nAssignee: #{work_package_with_due_date_and_assignee.assigned_to.name}\nAuthor: #{work_package_with_due_date_and_assignee.author.name}\nPriority: #{work_package_with_due_date_and_assignee.priority.name}\n\nDescription:\n#{work_package_with_due_date_and_assignee.description}
      LOCATION:http://localhost:3000/work_packages/#{work_package_with_due_date_and_assignee.id}
      SUMMARY:#{work_package_with_due_date_and_assignee.name}
      END:VEVENT
      END:VCALENDAR
    EOICAL

    expect(formatted_result).to eql(expected_ical_string)
  end
  # rubocop:enable RSpec/ExampleLength

  it "is a success" do
    expect(subject)
      .to be_success
  end

  describe "stripped and truncated workpackage description" do
    let(:work_package_with_rich_text_description) do
      create(:work_package, project:,
                            due_date: Time.zone.today + 7.days, assigned_to: user,
                            description: "test **description**\n\n1.  **foo**\n2.  bar\n3. **baz**")
    end
    let(:work_package_with_image) do
      create(:work_package, project:,
                            due_date: Time.zone.today + 7.days, assigned_to: user,
                            description: "test <img class=\"op-uc-image op-uc-image_inline\"
                            src=\"/api/v3/attachments/3/content\">image")
    end
    let(:work_package_with_long_text) do
      create(:work_package, project:,
                            due_date: Time.zone.today + 7.days, assigned_to: user,
                            description: "sit amet, consetetur sadipscing elitr, sed diam nonumy
                            eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam
                            voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
                            Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum
                            dolor sit amet.")
    end
    let(:work_packages) do
      [
        work_package_with_rich_text_description,
        work_package_with_image,
        work_package_with_long_text
      ]
    end

    it "strips html tags from the description" do
      expect(formatted_result).to include("test description") # no <b> tags
      expect(formatted_result).to include("\nfoo\nbar\nbaz") # no <br> tags or <ol> tags
    end

    it "strips images from the description" do
      expect(formatted_result).to include("test image") # no <img> tags
    end

    it "truncates the description at 250 chars" do
      expect(formatted_result).to include("sanctus est ...")
    end
  end

  describe "sanitized attributes" do
    # the iCalendar gem takes care of escaping malicious values
    # following specs double check on this behaviour
    let(:work_package_with_malicious_subject) do
      create(:work_package, subject: "<script>alert('Subject');</script>", project:,
                            due_date: Time.zone.today + 7.days, assigned_to: user)
    end
    let(:work_package_with_malicious_description) do
      create(:work_package, project:,
                            due_date: Time.zone.today + 7.days, assigned_to: user,
                            description: "<script>alert('Description');</script>")
    end
    let(:work_packages) do
      [
        work_package_with_malicious_subject,
        work_package_with_malicious_description
      ]
    end

    it "escapes malicious workpackage subject values" do
      expect(formatted_result).not_to include("<script>alert('Subject');</script>")
      expect(formatted_result).to include("&lt\\;script&gt\\;alert('Subject')\\;&lt\\;/script&gt\\;")
    end

    it "escapes malicious workpackage description values" do
      expect(formatted_result).not_to include("<script>alert('Description');</script>")
      expect(formatted_result).to include("&lt\\;script&gt\\;alert('Description')\\;&lt\\;/script&gt\\;")
    end
  end
end
