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

require "spec_helper"

require_relative "../support/pages/meetings/index"

RSpec.describe "Meetings", "Index", :js do
  shared_let(:business_day_at_noon) { Time.zone.local(2025, 1, 8, 12, 0, 0) }

  after do
    travel_back
  end

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

  shared_let(:meeting) do
    create(:meeting,
           :author_participates,
           project:,
           title: "Awesome meeting today!",
           start_time: business_day_at_noon - 5.minutes)
  end
  shared_let(:tomorrows_meeting) do
    create(:meeting,
           :author_participates,
           project:,
           title: "Awesome meeting tomorrow!",
           start_time: business_day_at_noon + 1.day,
           duration: 2.0,
           location: "no-protocol.com")
  end
  shared_let(:meeting_with_no_location) do
    create(:meeting,
           :author_participates,
           project:,
           title: "Boring meeting without a location!",
           start_time: business_day_at_noon + 1.day + 5.minutes,
           location: "")
  end
  shared_let(:meeting_with_malicious_location) do
    create(:meeting,
           :author_participates,
           project:,
           title: "Sneaky meeting!",
           start_time: business_day_at_noon + 1.day + 10.minutes,
           location: "<script>alert('Description');</script>")
  end
  shared_let(:yesterdays_meeting) do
    create(:meeting,
           :author_participates,
           project:,
           title: "Awesome meeting yesterday!",
           start_time: business_day_at_noon - 1.day)
  end

  shared_let(:other_project_meeting) do
    create(:meeting,
           :author_participates,
           project: other_project,
           title: "Awesome other project meeting!",
           start_time: business_day_at_noon + 2.days,
           duration: 2.0,
           location: "not-a-url")
  end
  shared_let(:ongoing_meeting) do
    create(:meeting,
           :author_participates,
           project:,
           title: "Awesome ongoing meeting!",
           start_time: business_day_at_noon - 30.minutes)
  end

  def setup_meeting_involvement
    create(:meeting_participant, :invitee, :attendee, user:, meeting: yesterdays_meeting)
    create(:meeting_participant, :invitee, :attendee, user:, meeting: tomorrows_meeting)
    meeting.update!(author: user)
  end

  def invite_to_meeting(meeting)
    create(:meeting_participant, :invitee, user:, meeting:)
  end

  before do
    travel_to(business_day_at_noon)
    login_as user
  end

  shared_examples "sidebar filtering" do |context:|
    context "when showing all meetings without invitations" do
      let!(:meeting_without_participants) do
        create(:meeting,
               project:,
               title: "Meeting without any participants!",
               start_time: business_day_at_noon + 3.hours).tap { |m| m.participants.delete_all }
      end

      it "does not show under My meetings, but in All meetings" do
        meetings_page.visit!
        meetings_page.expect_no_meetings_listed
        meetings_page.expect_blank_slate_component

        meetings_page.set_sidebar_filter "All meetings"

        # It now includes the ongoing meeting I'm not invited to,
        # as well as meetings without any invited participants
        expected_meetings =
          if context == :global
            [ongoing_meeting, meeting, meeting_without_participants, tomorrows_meeting, other_project_meeting]
          else
            [ongoing_meeting, meeting, meeting_without_participants, tomorrows_meeting]
          end
        meetings_page.expect_meetings_listed(*expected_meetings)
      end
    end

    context "when showing all meetings with the sidebar" do
      before do
        ongoing_meeting
        other_project_meeting
        setup_meeting_involvement
        meetings_page.visit!
        meetings_page.set_sidebar_filter "All meetings"
      end

      context 'with the "Upcoming meetings" quick filter' do
        before do
          meetings_page.set_quick_filter upcoming: true
        end

        it "shows all upcoming and ongoing meetings", :aggregate_failures do
          expected_upcoming_meetings =
            if context == :global
              [ongoing_meeting, meeting, tomorrows_meeting, meeting_with_no_location,
               meeting_with_malicious_location, other_project_meeting]
            else
              [ongoing_meeting, meeting, tomorrows_meeting, meeting_with_no_location, meeting_with_malicious_location]
            end

          meetings_page.expect_meetings_listed_in_order(*expected_upcoming_meetings)
          meetings_page.expect_meetings_not_listed(yesterdays_meeting)
        end
      end

      context 'with the "Past meetings" quick filter' do
        before do
          meetings_page.set_quick_filter upcoming: false
        end

        it "show all past meetings" do
          meetings_page.expect_meetings_listed_in_table(yesterdays_meeting, meeting, ongoing_meeting)
          meetings_page.expect_meetings_not_listed(tomorrows_meeting)
        end

        it "keeps the past filter selected when changing advanced filters (Regression #61875)" do
          meetings_page.set_sidebar_filter "My meetings"
          meetings_page.set_quick_filter upcoming: false

          meetings_page.open_filters
          meetings_page.remove_filter "invited_user_id"

          wait_for_network_idle

          sort = [["start_time", "desc"]].to_json
          time_filters = [{ "time" => { "operator" => "past", "values" => [] } }].to_json
          if context == :global
            expect(page).to have_current_path(meetings_path(filters: time_filters, sortBy: sort))
          else
            expect(page).to have_current_path(project_meetings_path(project, filters: time_filters, sortBy: sort))
          end
        end
      end

      context 'when applying the "Past" time filter without sortBy (Bug #75159)' do
        let(:one_hour_ago_meeting) do
          create(:meeting,
                 project:,
                 title: "One hour ago meeting",
                 start_time: business_day_at_noon - 1.hour)
        end
        let(:three_hours_ago_meeting) do
          create(:meeting,
                 project:,
                 title: "Three hours ago meeting",
                 start_time: business_day_at_noon - 3.hours)
        end

        before do
          three_hours_ago_meeting
          one_hour_ago_meeting
        end

        it "shows past meetings sorted by descending start time" do
          # On mobile the segmented quick filter is hidden, so users apply the past
          # filter via the all filters form. That form does not add sortBy to the URL.
          # The backend must apply start_time: :desc as a default in this case
          time_filters = [{ "time" => { "operator" => "past", "values" => [] } }].to_json

          if context == :global
            visit meetings_path(filters: time_filters)
          else
            visit project_meetings_path(project, filters: time_filters)
          end

          wait_for_network_idle

          meetings_page.expect_meetings_listed_in_order(
            meeting,
            ongoing_meeting,
            one_hour_ago_meeting,
            three_hours_ago_meeting,
            yesterdays_meeting
          )
          meetings_page.expect_meetings_not_listed(tomorrows_meeting)
        end
      end

      context "when the time filter is removed via the all filters form" do
        before do
          meetings_page.set_quick_filter upcoming: true
        end

        it "lets the quick filter enter an unselected state" do
          meetings_page.expect_quick_filter_selected "Upcoming"

          meetings_page.open_filters
          meetings_page.remove_filter "time"

          wait_for_network_idle

          meetings_page.expect_quick_filter_unselected
        end
      end

      context 'with the "Attendee" filter' do
        before do
          meetings_page.set_sidebar_filter "Attended"
        end

        it "shows all past meetings I've been marked as attending to" do
          meetings_page.expect_meetings_listed(yesterdays_meeting)
          meetings_page.expect_meetings_not_listed(meeting,
                                                   ongoing_meeting,
                                                   tomorrows_meeting)

          # Switch to upcoming
          meetings_page.set_quick_filter upcoming: true

          meetings_page.expect_meetings_listed(tomorrows_meeting)
          meetings_page.expect_meetings_not_listed(yesterdays_meeting,
                                                   meeting,
                                                   ongoing_meeting)
        end
      end

      context 'with the "Creator" filter' do
        before do
          meetings_page.set_sidebar_filter "Created by me"
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
      meetings_page.expect_meeting_listed_in_group(meeting, key: :today)
      meetings_page.expect_meeting_listed_in_group(other_project_meeting)
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

    context "and the user is only allowed to view meetings" do
      let(:permissions) { %i[view_meetings] }

      it "doesn't show a create new button" do
        meetings_page.visit!

        meetings_page.expect_no_create_new_button
      end

      it "shows a download ical event action button for each meeting" do
        invite_to_meeting(meeting)
        meetings_page.visit!

        meetings_page.expect_ical_action(meeting)
      end

      it "doesn't show a copy meeting action button for each meeting" do
        invite_to_meeting(meeting)
        meetings_page.visit!

        meetings_page.expect_no_copy_action(meeting)
      end

      it "doesn't show a delete meeting action button for each meeting" do
        invite_to_meeting(meeting)
        meetings_page.visit!

        meetings_page.expect_no_delete_action(meeting)
      end
    end

    context "and the user is allowed to create meetings" do
      let(:permissions) { %i(view_meetings create_meetings) }

      it "shows the create new button" do
        meetings_page.visit!

        meetings_page.expect_create_new_button
      end

      it "allows creation of both types of meetings" do
        meetings_page.visit!

        meetings_page.expect_create_new_types
      end

      it "shows a copy meeting action button for each meeting" do
        invite_to_meeting(meeting)
        meetings_page.visit!

        meetings_page.expect_copy_action(meeting)
      end
    end

    context "and the user is allowed to delete meetings" do
      let(:permissions) { %i(view_meetings delete_meetings) }

      it "shows a delete meeting action button for each meeting" do
        invite_to_meeting(meeting)
        meetings_page.visit!

        meetings_page.expect_delete_action(meeting)
      end
    end

    context 'with the "Project" quick filter' do
      before do
        meetings_page.visit!
        meetings_page.set_sidebar_filter "All meetings"
      end

      it "shows only meetings from the selected projects" do
        meetings_page.set_project_filter(project)

        meetings_page.expect_meetings_listed(meeting, tomorrows_meeting)
        meetings_page.expect_meetings_not_listed(other_project_meeting)

        meetings_page.set_project_filter(project, other_project)

        meetings_page.expect_meetings_listed(meeting, tomorrows_meeting, other_project_meeting)
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
        meetings_page.expect_blank_slate_component
      end
    end

    context "when the user is allowed to create meetings" do
      let(:permissions) { %i(view_meetings create_meetings) }

      it "shows the create new button" do
        meetings_page.visit!
        meetings_page.expect_create_new_button
      end
    end

    context "when the user is not allowed to create meetings" do
      let(:permissions) { %i[view_meetings] }

      it "doesn't show the create new button" do
        meetings_page.visit!
        meetings_page.expect_no_create_new_button
      end
    end

    it 'does not show the "Project" quick filter' do
      meetings_page.visit!
      expect(page).to have_no_button I18n.t(:label_project), exact: true
    end

    include_examples "sidebar filtering", context: :project

    specify "with 1 meeting listed" do
      invite_to_meeting(meeting)
      meetings_page.visit!

      meetings_page.expect_meetings_listed(meeting)
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
  end

  describe "top level menu items and breadcrumbs (Regression #61343)" do
    let(:meetings_page) { Pages::Meetings::Index.new(project: nil) }

    context "when the user is logged in and specific filters are selected" do
      it "shows the correct selected menu item and breadcrumb each time" do
        meetings_page.visit!

        expect(page).to have_css(".op-submenu--item-action.selected", text: "My meetings")
        expect(page).to have_css("li.breadcrumb-item-selected", text: "My meetings")

        meetings_page.set_sidebar_filter("Recurring meetings")

        expect(page).to have_css(".op-submenu--item-action.selected", text: "Recurring meetings")
        expect(page).to have_css("li.breadcrumb-item-selected", text: "Recurring meetings")

        meetings_page.set_sidebar_filter("All meetings")

        expect(page).to have_css(".op-submenu--item-action.selected", text: "All meetings")
        expect(page).to have_css("li.breadcrumb-item-selected", text: "All meetings")
      end
    end
  end

  describe "top level menu items and breadcrumbs anonymously (Regression #61343)" do
    let(:user) do
      create(:anonymous_role, permissions: %i[view_project view_meetings])
      User.anonymous
    end
    let(:project) { create(:public_project, enabled_module_names: %i[meetings]) }
    let(:meetings_page) { Pages::Meetings::Index.new(project:) }

    context "when the user is logged out and specific filters are selected", with_settings: { login_required?: false } do
      it "shows the correct selected menu item and breadcrumb each time" do
        meetings_page.visit!

        # with no filter
        expect(page).to have_css(".op-submenu--item-action.selected", text: "All meetings")
        expect(page).to have_css("li.breadcrumb-item-selected", text: "All meetings")

        meetings_page.set_sidebar_filter("Recurring meetings")

        expect(page).to have_css(".op-submenu--item-action.selected", text: "Recurring meetings")
        expect(page).to have_css("li.breadcrumb-item-selected", text: "Recurring meetings")

        # with an explicitly selected filter
        meetings_page.set_sidebar_filter("All meetings")

        expect(page).to have_css(".op-submenu--item-action.selected", text: "All meetings")
        expect(page).to have_css("li.breadcrumb-item-selected", text: "All meetings")
      end
    end
  end
end
