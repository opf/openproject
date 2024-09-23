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

RSpec.describe "Meetings copy", :js, :with_cuprite do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:permissions) { %i[view_meetings create_meetings] }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => permissions }).tap do |u|
      u.pref[:time_zone] = "UTC"

      u.save!
    end
  end
  shared_let(:other_user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end

  shared_let(:start_time) { Time.current.next_day.at_noon }
  shared_let(:duration) { 1.5 }
  shared_let(:agenda_text) { "We will talk" }
  shared_let(:meeting) do
    create(:meeting,
           author: user,
           project:,
           title: "Awesome meeting!",
           location: "Meeting room",
           duration:,
           start_time:).tap do |m|
      create(:meeting_agenda, meeting: m, text: agenda_text)
      create(:meeting_participant, :attendee, meeting: m, user: other_user)
    end
  end

  shared_let(:twelve_hour_format) { "%I:%M %p" }
  shared_let(:copied_meeting_time_heading) do
    date = (start_time + 1.week).strftime("%m/%d/%Y")
    start_of_meeting = start_time.strftime(twelve_hour_format)
    end_of_meeting = (start_time + meeting.duration.hours).strftime(twelve_hour_format)

    "Start time: #{date} #{start_of_meeting} - #{end_of_meeting} (GMT+00:00) UTC"
  end

  before do
    login_as user
  end

  it "copying a meeting" do
    visit project_meetings_path(project)

    click_on meeting.title

    find_test_selector("meetings-more-dropdown-menu").click
    page.within(".menu-drop-down-container") do
      click_on "Copy"
    end

    expect(page)
      .to have_field "Title",      with: meeting.title
    expect(page)
      .to have_field "Location",   with: meeting.location
    expect(page)
      .to have_field "Duration",   with: meeting.duration
    expect(page)
      .to have_field "Start date", with: (start_time + 1.week).strftime("%Y-%m-%d")
    expect(page)
      .to have_field "Time",       with: start_time.strftime("%H:%M")

    click_on "Create"

    # Be on the new meeting's page with copied over attributes
    expect(page).to have_no_current_path meeting_path(meeting.id)

    expect(page)
      .to have_content("Added by #{user.name}")
    expect(page)
      .to have_content("Meeting: #{meeting.title}")
    expect(page)
      .to have_content(copied_meeting_time_heading)
    expect(page)
      .to have_content("Location: #{meeting.location}")

    # Copies the invitees
    expect(page)
      .to have_content "Invitees: #{other_user.name}"

    # Does not copy the attendees
    expect(page)
      .to have_no_content "Attendees: #{other_user.name}"
    expect(page)
      .to have_content "Attendees:"

    # Copies the agenda
    click_on "Agenda"
    expect(page)
      .to have_content agenda_text

    # Adds an entry to the history
    click_on "History"
    expect(page)
      .to have_content("Copied from Meeting ##{meeting.id}")
  end
end
