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
require_relative "../support/pages/meetings/show"

RSpec.describe "Meetings", :js do
  let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:role) { create(:project_role, permissions:) }
  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end

  let!(:meeting) { create(:meeting, project:, title: "Awesome meeting!") }
  let(:show_page) { Pages::Meetings::Show.new(meeting) }

  current_user { user }

  describe "navigate to meeting page" do
    before do
      create(:meeting_participant, :invitee, user:, meeting:)
    end

    let(:permissions) { %i[view_meetings] }

    it "can visit the meeting" do
      visit meetings_path(project)

      find("td.title a", text: "Awesome meeting!", wait: 10).click
      expect(page).to have_css("h2", text: "Meeting: Awesome meeting!")

      expect(page).to have_test_selector("op-meeting--meeting_agenda",
                                         text: "There is currently nothing to display")
    end

    context "with a location" do
      context "as a valid url" do
        it "renders a link to the meeting location" do
          show_page.visit!

          show_page.expect_link_to_location(meeting.location)
        end
      end

      context "as an invalid url" do
        before do
          meeting.update!(location: "badurl")
        end

        it "renders the meeting location as plaintext" do
          show_page.visit!

          show_page.expect_plaintext_location(meeting.location)
        end
      end
    end

    context "with an open agenda" do
      let!(:agenda) { create(:meeting_agenda, meeting:, text: "foo") }
      let(:agenda_update) { create(:meeting_agenda, meeting:, text: "bla") }

      it "shows the agenda" do
        visit meeting_path(meeting)
        expect(page).to have_test_selector("op-meeting--meeting_agenda",
                                           text: "foo")

        # May not edit
        expect(page).to have_no_css(".button--edit-agenda")
        expect(page).not_to have_test_selector("op-meeting--meeting_agenda",
                                               text: "Edit")
      end

      it "can view history" do
        agenda_update

        visit meeting_path(meeting)

        click_on "History"

        find_by_id("version-1").click
        expect(page).to have_test_selector("op-meeting--meeting_agenda", text: "foo")
      end

      context "and edit permissions" do
        let(:permissions) { %i[view_meetings create_meeting_agendas] }
        let(:field) do
          TextEditorField.new(page,
                              "",
                              selector: test_selector("op-meeting--meeting_agenda"))
        end

        it "can edit the agenda" do
          visit meeting_path(meeting)

          find(".toolbar-item", text: "Edit").click

          field.expect_value("foo")

          field.set_value("My new meeting text")

          field.submit_by_enter

          show_page.expect_and_dismiss_toaster message: "Successful update"

          meeting.reload

          expect(meeting.agenda.text).to eq "My new meeting text"
        end
      end

      context "and edit minutes permissions" do
        let(:permissions) { %i[view_meetings create_meeting_minutes] }

        it "can not edit the minutes" do
          visit meeting_path(meeting)
          click_on "Minutes"
          expect(page).not_to have_test_selector("op-meeting--meeting_minutes", text: "Edit")
          expect(page).to have_test_selector("op-meeting--meeting_minutes",
                                             text: "There is currently nothing to display")
        end
      end
    end

    context "with a locked agenda" do
      let!(:agenda) { create(:meeting_agenda, meeting:, text: "foo", locked: true) }

      it "shows the minutes when visiting" do
        visit meeting_path(meeting)
        expect(page).to have_no_css("h2", text: "Agenda")
        expect(page).to have_no_css("#meeting_minutes_text")
        expect(page).to have_css("h2", text: "Minutes")
      end

      context "and edit permissions" do
        let(:permissions) { %i[view_meetings create_meeting_minutes] }
        let(:field) do
          TextEditorField.new(page,
                              "",
                              selector: test_selector("op-meeting--meeting_minutes"))
        end

        it "can edit the minutes" do
          visit meeting_path(meeting)

          field.set_value("This is what we talked about")

          click_on "Save"

          expect(page)
            .to have_css(".op-uc-container",
                         text: "This is what we talked about")
        end
      end
    end
  end
end
