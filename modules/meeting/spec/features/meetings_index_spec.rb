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

require_relative "../support/pages/meetings/index"

RSpec.describe "Meetings", "Index", :js, :with_cuprite do
  # The order the Projects are created in is important. By naming `project` alphanumerically
  # after `other_project`, we can ensure that subsequent specs that assert sorting is
  # correct for the right reasons (sorting by Project name and not id)
  shared_let(:project) { create(:project, name: "Project 2", enabled_module_names: %w[meetings]) }
  shared_let(:other_project) { create(:project, name: "Project 1", enabled_module_names: %w[meetings]) }
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i(view_meetings) }
  let(:user) do
    create(:user) do |user|
      [project, other_project].each do |p|
        create(:member,
               project: p,
               principal: user,
               roles: [role])
      end
    end
  end

  let(:meeting) do
    create(:meeting,
           project:,
           title: "Awesome meeting today!",
           start_time: Time.current)
  end
  let(:tomorrows_meeting) do
    create(:meeting,
           project:,
           title: "Awesome meeting tomorrow!",
           start_time: 1.day.from_now,
           duration: 2.0,
           location: "no-protocol.com")
  end
  let(:meeting_with_no_location) do
    create(:meeting,
           project:,
           title: "Boring meeting without a location!",
           start_time: 1.day.from_now,
           location: "")
  end
  let(:meeting_with_malicious_location) do
    create(:meeting,
           project:,
           title: "Sneaky meeting!",
           start_time: 1.day.from_now,
           location: "<script>alert('Description');</script>")
  end
  let(:yesterdays_meeting) do
    create(:meeting, project:, title: "Awesome meeting yesterday!", start_time: 1.day.ago)
  end

  let(:other_project_meeting) do
    create(:meeting,
           project: other_project,
           title: "Awesome other project meeting!",
           start_time: 2.days.from_now,
           duration: 2.0,
           location: "not-a-url")
  end
  let(:ongoing_meeting) do
    create(:meeting, project:, title: "Awesome ongoing meeting!", start_time: 30.minutes.ago)
  end

  def setup_meeting_involvement
    invite_to_meeting(tomorrows_meeting)
    invite_to_meeting(yesterdays_meeting)
    create(:meeting_participant, :attendee, user:, meeting:)
    meeting.update!(author: user)
  end

  def invite_to_meeting(meeting)
    create(:meeting_participant, :invitee, user:, meeting:)
  end

  before do
    login_as user
  end

  shared_examples "sidebar filtering" do |context:|
    context "when filtering with the sidebar" do
      before do
        ongoing_meeting
        other_project_meeting
        setup_meeting_involvement
        meetings_page.visit!
      end

      context 'with the "Upcoming meetings" filter' do
        before do
          meetings_page.set_sidebar_filter "Upcoming meetings"
        end

        it "shows all upcoming and ongoing meetings", :aggregate_failures do
          expected_upcoming_meetings = if context == :global
                                         [ongoing_meeting, meeting, tomorrows_meeting, other_project_meeting]
                                       else
                                         [ongoing_meeting, meeting, tomorrows_meeting]
                                       end

          meetings_page.expect_meetings_listed_in_order(*expected_upcoming_meetings)
          meetings_page.expect_meetings_not_listed(yesterdays_meeting)
        end
      end

      context 'with the "Past meetings" filter' do
        before do
          meetings_page.set_sidebar_filter "Past meetings"
        end

        it "show all past and ongoing meetings" do
          meetings_page.expect_meetings_listed_in_order(ongoing_meeting,
                                                        yesterdays_meeting)
          meetings_page.expect_meetings_not_listed(meeting,
                                                   tomorrows_meeting)
        end
      end

      context 'with the "Upcoming invitations" filter' do
        before do
          meetings_page.set_sidebar_filter "Upcoming invitations"
        end

        it "shows all upcoming meetings I've been marked as invited to" do
          meetings_page.expect_meetings_listed(tomorrows_meeting)
          meetings_page.expect_meetings_not_listed(yesterdays_meeting,
                                                   meeting,
                                                   ongoing_meeting)
        end
      end

      context 'with the "Past invitations" filter' do
        before do
          meetings_page.set_sidebar_filter "Past invitations"
        end

        it "shows all past meetings I've been marked as invited to" do
          meetings_page.expect_meetings_listed(yesterdays_meeting)
          meetings_page.expect_meetings_not_listed(ongoing_meeting,
                                                   meeting,
                                                   tomorrows_meeting)
        end
      end

      context 'with the "Attendee" filter' do
        before do
          meetings_page.set_sidebar_filter "Attendee"
        end

        it "shows all meetings I've been marked as attending to" do
          meetings_page.expect_meetings_listed(meeting)
          meetings_page.expect_meetings_not_listed(yesterdays_meeting,
                                                   ongoing_meeting,
                                                   tomorrows_meeting)
        end
      end

      context 'with the "Creator" filter' do
        before do
          meetings_page.set_sidebar_filter "Creator"
        end

        it "shows all meetings I'm the author of" do
          meetings_page.expect_meetings_listed(meeting)
          meetings_page.expect_meetings_not_listed(yesterdays_meeting,
                                                   ongoing_meeting,
                                                   tomorrows_meeting)
        end
      end
    end
  end

  context "when visiting from a global context" do
    let(:meetings_page) { Pages::Meetings::Index.new(project: nil) }

    it "lists all upcoming meetings for all projects the user is invited to" do
      invite_to_meeting(meeting)
      invite_to_meeting(yesterdays_meeting)
      invite_to_meeting(other_project_meeting)

      meetings_page.visit!
      meetings_page.expect_meetings_listed(meeting, other_project_meeting)
      meetings_page.expect_meetings_not_listed(yesterdays_meeting)
    end

    it "renders a link to each meeting's location if present and a valid URL" do
      invite_to_meeting(meeting)
      invite_to_meeting(meeting_with_no_location)
      invite_to_meeting(meeting_with_malicious_location)
      invite_to_meeting(tomorrows_meeting)
      invite_to_meeting(other_project_meeting)

      meetings_page.visit!

      meetings_page.expect_link_to_meeting_location(meeting)
      meetings_page.expect_plaintext_meeting_location(tomorrows_meeting)
      meetings_page.expect_plaintext_meeting_location(other_project_meeting)
      meetings_page.expect_plaintext_meeting_location(meeting_with_malicious_location)
      meetings_page.expect_no_meeting_location(meeting_with_no_location)
    end

    context "and the user is allowed to create meetings" do
      let(:permissions) { %i(view_meetings create_meetings) }

      it "shows the create new buttons" do
        meetings_page.visit!

        meetings_page.expect_create_new_buttons
      end
    end

    context "and the user is not allowed to create meetings" do
      let(:permissions) { %i[view_meetings] }

      it "doesn't show a create new button" do
        meetings_page.visit!

        meetings_page.expect_no_create_new_buttons
      end
    end

    describe "sorting" do
      before do
        invite_to_meeting(meeting)
        invite_to_meeting(other_project_meeting)
        visit meetings_path
        # Start Time ASC is the default sort order for Upcoming meetings
        # We can assert the initial sort by expecting the order is
        # 1. `meeting`
        # 2. `other_project_meeting`
        # upon page load
        meetings_page.expect_meetings_listed_in_order(meeting, other_project_meeting)
      end

      it "allows sorting by every column" do
        aggregate_failures "Sorting by Title" do
          meetings_page.click_to_sort_by("Title")
          meetings_page.expect_meetings_listed_in_order(meeting,
                                                        other_project_meeting)
          meetings_page.click_to_sort_by("Title")
          meetings_page.expect_meetings_listed_in_order(other_project_meeting,
                                                        meeting)
        end

        aggregate_failures "Sorting by Project" do
          meetings_page.click_to_sort_by("Project")
          meetings_page.expect_meetings_listed_in_order(other_project_meeting,
                                                        meeting)
          meetings_page.click_to_sort_by("Project")
          meetings_page.expect_meetings_listed_in_order(meeting,
                                                        other_project_meeting)
        end

        aggregate_failures "Sorting by Start time" do
          meetings_page.click_to_sort_by("Start time")
          meetings_page.expect_meetings_listed_in_order(meeting,
                                                        other_project_meeting)
          meetings_page.click_to_sort_by("Start time")
          meetings_page.expect_meetings_listed_in_order(other_project_meeting,
                                                        meeting)
        end

        aggregate_failures "Sorting by Duration" do
          meetings_page.click_to_sort_by("Duration")
          meetings_page.expect_meetings_listed_in_order(meeting,
                                                        other_project_meeting)
          meetings_page.click_to_sort_by("Duration")
          meetings_page.expect_meetings_listed_in_order(other_project_meeting,
                                                        meeting)
        end

        aggregate_failures "Sorting by Location" do
          meetings_page.click_to_sort_by("Location")
          meetings_page.expect_meetings_listed_in_order(meeting,
                                                        other_project_meeting)
          meetings_page.click_to_sort_by("Location")
          meetings_page.expect_meetings_listed_in_order(other_project_meeting,
                                                        meeting)
        end
      end
    end

    include_examples "sidebar filtering", context: :global
  end

  context "when visiting from a project specific context" do
    let(:meetings_page) { Pages::Meetings::Index.new(project:) }

    context "via the menu" do
      specify "with no meetings" do
        meetings_page.navigate_by_project_menu

        meetings_page.expect_no_meetings_listed
      end
    end

    context "when the user is allowed to create meetings" do
      let(:permissions) { %i(view_meetings create_meetings) }

      it "shows the create new buttons" do
        meetings_page.visit!
        meetings_page.expect_create_new_buttons
      end
    end

    context "when the user is not allowed to create meetings" do
      let(:permissions) { %i[view_meetings] }

      it "doesn't show the create new buttons" do
        meetings_page.visit!
        meetings_page.expect_no_create_new_buttons
      end
    end

    include_examples "sidebar filtering", context: :project

    specify "with 1 meeting listed" do
      invite_to_meeting(meeting)
      meetings_page.visit!

      meetings_page.expect_meetings_listed(meeting)
    end

    it "with pagination", with_settings: { per_page_options: "1" } do
      invite_to_meeting(meeting)
      invite_to_meeting(tomorrows_meeting)
      invite_to_meeting(yesterdays_meeting)

      # First page displays the soonest occurring upcoming meeting
      meetings_page.visit!
      meetings_page.expect_meetings_listed(meeting)
      meetings_page.expect_meetings_not_listed(yesterdays_meeting, # Past meetings not displayed
                                               tomorrows_meeting)

      meetings_page.expect_to_be_on_page(1)

      # Second page shows the next occurring upcoming meeting
      meetings_page.to_page(2)
      meetings_page.expect_meetings_listed(tomorrows_meeting)
      meetings_page.expect_meetings_not_listed(yesterdays_meeting, # Past meetings not displayed
                                               meeting)
    end

    it "renders a link to each meeting's location if present and a valid URL" do
      invite_to_meeting(meeting)
      invite_to_meeting(meeting_with_no_location)
      invite_to_meeting(meeting_with_malicious_location)
      invite_to_meeting(tomorrows_meeting)

      meetings_page.visit!
      meetings_page.expect_link_to_meeting_location(meeting)
      meetings_page.expect_plaintext_meeting_location(tomorrows_meeting)
      meetings_page.expect_plaintext_meeting_location(meeting_with_malicious_location)
      meetings_page.expect_no_meeting_location(meeting_with_no_location)
    end

    describe "sorting" do
      before do
        invite_to_meeting(meeting)
        invite_to_meeting(tomorrows_meeting)
        meetings_page.visit!
        # Start Time ASC is the default sort order for Upcoming meetings
        # We can assert the initial sort by expecting the order is
        # 1. `meeting`
        # 2. `tomorrows_meeting`
        # upon page load
        meetings_page.expect_meetings_listed_in_order(meeting, tomorrows_meeting)
      end

      it "allows sorting by every column" do
        aggregate_failures "Sorting by Title" do
          meetings_page.click_to_sort_by("Title")
          meetings_page.expect_meetings_listed_in_order(meeting,
                                                        tomorrows_meeting)
          meetings_page.click_to_sort_by("Title")
          meetings_page.expect_meetings_listed_in_order(tomorrows_meeting,
                                                        meeting)
        end

        aggregate_failures "Sorting by Start time" do
          meetings_page.click_to_sort_by("Start time")
          meetings_page.expect_meetings_listed_in_order(meeting,
                                                        tomorrows_meeting)
          meetings_page.click_to_sort_by("Start time")
          meetings_page.expect_meetings_listed_in_order(tomorrows_meeting,
                                                        meeting)
        end

        aggregate_failures "Sorting by Start time" do
          meetings_page.click_to_sort_by("Start time")
          meetings_page.expect_meetings_listed_in_order(meeting,
                                                        tomorrows_meeting)
          meetings_page.click_to_sort_by("Start time")
          meetings_page.expect_meetings_listed_in_order(tomorrows_meeting,
                                                        meeting)
        end

        aggregate_failures "Sorting by Duration" do
          meetings_page.click_to_sort_by("Duration")
          meetings_page.expect_meetings_listed_in_order(meeting,
                                                        tomorrows_meeting)
          meetings_page.click_to_sort_by("Duration")
          meetings_page.expect_meetings_listed_in_order(tomorrows_meeting,
                                                        meeting)
        end

        aggregate_failures "Sorting by Duration" do
          meetings_page.click_to_sort_by("Duration")
          meetings_page.expect_meetings_listed_in_order(meeting,
                                                        tomorrows_meeting)
          meetings_page.click_to_sort_by("Duration")
          meetings_page.expect_meetings_listed_in_order(tomorrows_meeting,
                                                        meeting)
        end

        aggregate_failures "Sorting by Location" do
          meetings_page.click_to_sort_by("Location")
          meetings_page.expect_meetings_listed_in_order(meeting,
                                                        tomorrows_meeting)
          meetings_page.click_to_sort_by("Location")
          meetings_page.expect_meetings_listed_in_order(tomorrows_meeting,
                                                        meeting)
        end
      end
    end
  end
end
