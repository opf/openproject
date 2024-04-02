#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require_relative "../../support/pages/meetings/new"
require_relative "../../support/pages/structured_meeting/show"
require_relative "../../support/pages/structured_meeting/history"

RSpec.describe "history",
               :js,
               :with_cuprite do
  include Components::Autocompleter::NgSelectAutocompleteHelpers
  include Redmine::I18n

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user,
           lastname: "First",
           preferences: { time_zone: "Europe/London" },
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings manage_agendas
                                                    view_work_packages] })
  end
  shared_let(:view_only_user) do
    create(:user,
           lastname: "Second",
           preferences: { time_zone: "Europe/London" },
           member_with_permissions: { project => %i[view_meetings view_work_packages] })
  end
  shared_let(:no_member_user) do
    create(:user,
           lastname: "Third")
  end
  shared_let(:meeting) do
    User.execute_as(user) do
      create(:structured_meeting,
             project:,
             start_time: DateTime.parse("2024-03-28T13:30:00Z"),
             title: "Some title",
             duration: 1.5).tap do |m|
        create(:meeting_participant, :invitee, meeting: m, user: view_only_user)
      end
    end
  end

  let(:show_page) { Pages::StructuredMeeting::Show.new(meeting) }
  let(:history_page) { Pages::StructuredMeeting::History.new(meeting) }

  it "for a user with view permissions", with_settings: { journal_aggregation_time_minutes: 0 } do
    login_as(view_only_user)

    # Create meeting
    show_page.visit!

    history_page.open_history_modal

    history_page.expect_event("Meeting",
                              actor: user.name,
                              timestamp: format_time(meeting.created_at.utc),
                              action: "created by")

    # Update meeting
    login_as(user)
    meeting.update!(start_time: DateTime.parse("2024-03-29T14:00:00Z"),
                    duration: 1,
                    title: "Updated",
                    location: "Wakanda")
    login_as(view_only_user)

    page.refresh

    history_page.open_history_modal
    history_page.expect_event("Meeting details",
                              actor: user.name,
                              timestamp: format_time(meeting.updated_at.utc),
                              action: "updated by")

    item = history_page.find_item("Title changed from Some title to Updated")
    within(item) do
      expect(page).to have_css(".op-activity-list--item-title", text: "Meeting details")
      expect(page).to have_css("li", text: "Location changed from https://some-url.com to Wakanda")
      expect(page).to have_css("li", text: "Start time changed from 03/28/2024 01:30 PM to 03/29/2024 02:00 PM")
      expect(page).to have_css("li", text: "Duration changed from 1 hr, 30 mins to 1 hr")
    end

    # Add agenda item
    binding.pry # not sure what's going on here as if I go command by command in pry it works
    login_as(user) # but if I run the test it fails as it can't find the button
    # page.refresh
    sleep(5)
    show_page.add_agenda_item do
      fill_in "Title", with: "My agenda item"
      fill_in "Duration (min)", with: "25"
    end
    login_as(view_only_user)
    # page.refresh

    item = MeetingAgendaItem.find_by(title: "My agenda item")
    history_page.open_history_modal
    history_page.expect_event('Agenda item "My agenda item"',
                              timestamp: format_time(item.created_at.utc),
                              action: "created by")

    within("li.op-activity-list--item", match: :first) do
      expect(page).to have_css(".op-activity-list--item-title", text: 'Agenda item "My agenda item"')
    end

    # Update agenda item
    item = MeetingAgendaItem.find_by(title: "My agenda item")
    show_page.edit_agenda_item(item) do
      fill_in "Title", with: "Updated title"
      fill_in "Duration", with: "5"
      click_on "Save"
    end

    history_page.open_history_modal
    history_page.expect_event('Agenda item "Updated title"',
                          actor: user.name,
                          timestamp: format_time(item.updated_at.utc),
                          action: "updated by")

    within("li.op-activity-list--item", match: :first) do
      expect(page).to have_css("li", text: "Title changed from My agenda item to Updated title")
      expect(page).to have_css("li", text: "Duration changed from 25 minutes to 5 minutes")
    end

    # Change position, expect only one change
    login_as(user)
    show_page.add_agenda_item do
      fill_in "Title", with: "Second"
    end
    second = MeetingAgendaItem.find_by(title: "Second")
    show_page.select_action(second, I18n.t(:label_sort_higher))
    login_as(view_only_user)

    history_page.open_history_modal

    item = history_page.find_item("Agenda items reordered") # using this as no error here indicates exactly 1
    within(item) do
      expect(page).to have_css(".op-activity-list--item-title", text: "Meeting details")
      expect(page).to have_text("updated by")
      expect(page).to have_text(user.name)
    end

    # Remove agenda item
    login_as(user)
    show_page.remove_agenda_item(second)
    login_as(view_only_user)

    history_page.open_history_modal
    history_page.expect_event('Agenda item "Second"',
                              actor: user.name,
                              timestamp: format_time(meeting.created_at.utc), # don't know how to check time here
                              action: "deleted by")

    # Remove linked work package
    # TODO

    # With a work package linked in another project
    # TODO
  end

  it "for a user with no permissions", with_settings: { journal_aggregation_time_minutes: 0 } do
    login_as no_member_user

    visit history_meeting_path(meeting)

    expected = "[Error 403] You are not authorized to access this page."
    expect(page).to have_css(".op-toast.-error", text: expected)
  end
end
