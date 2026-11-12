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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

require_relative "../../support/pages/meetings/show"

RSpec.describe "Meeting presentation mode move actions", :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create :user,
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings edit_meetings manage_agendas] }
  end
  shared_let(:series) do
    create :recurring_meeting,
           project:,
           start_time: DateTime.parse("2025-01-28T10:30:00Z"),
           duration: 1,
           frequency: "weekly",
           end_after: "never",
           author: user
  end
  shared_let(:meeting) do
    create :recurring_meeting_occurrence,
           recurring_meeting: series,
           start_time: DateTime.parse("2025-01-28T10:30:00Z"),
           state: :in_progress,
           title: "Weekly sync"
  end
  shared_let(:viewer) do
    create :user,
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings] }
  end
  shared_let(:first_item) { create(:meeting_agenda_item, meeting:, title: "First Item") }
  shared_let(:second_item) { create(:meeting_agenda_item, meeting:, title: "Second Item") }

  let(:show_page) { Pages::Meetings::Show.new(meeting) }

  before { login_as user }

  def visit_presentation
    visit project_meeting_presentation_path(project, meeting)
    expect(page).to have_css(".op-meeting-presentation")
  end

  it "exposes move-to-backlog and move-to-next-meeting actions" do
    visit_presentation
    expect(page).to have_text("First Item")

    show_page.open_menu(first_item) do
      expect(page).to have_text("Move")

      expect(page).to have_no_text("Duplicate")
      expect(page).to have_no_text("Delete")

      click_on "Move"

      expect(page).to have_text("Move to backlog")
      expect(page).to have_text("Move to next meeting")

      expect(page).to have_no_text("Move to top")
      expect(page).to have_no_text("Move up")
      expect(page).to have_no_text("Move to section")
    end
  end

  it "moves an item to the backlog, advances to the next slide and shows a banner" do
    visit_presentation
    within_test_selector("meeting-presentation-agenda-item") { expect(page).to have_text("First Item") }
    expect(page).to have_text("1 of 2")

    show_page.select_action(first_item, "Move to backlog")

    expect_and_dismiss_flash(message: "Agenda item moved to the backlog")

    within_test_selector("meeting-presentation-agenda-item") do
      expect(page).to have_text("Second Item")
      expect(page).to have_no_text("First Item")
    end
    expect(page).to have_text("1 of 1")

    expect(first_item.reload).to be_in_backlog
  end

  it "moves an item to the next meeting, advances to the next slide and shows a banner" do
    visit_presentation
    within_test_selector("meeting-presentation-agenda-item") { expect(page).to have_text("First Item") }

    show_page.move_item_to_next_meeting(first_item)

    expect_and_dismiss_flash(message: "Agenda item moved to the next meeting")

    within_test_selector("meeting-presentation-agenda-item") do
      expect(page).to have_text("Second Item")
      expect(page).to have_no_text("First Item")
    end

    expect(meeting.agenda_items.reload).not_to include(first_item)
  end

  context "when moving the last remaining item out of the meeting" do
    before { second_item.destroy }

    it "leaves presentation mode and shows the banner on the meeting page" do
      visit_presentation
      within_test_selector("meeting-presentation-agenda-item") { expect(page).to have_text("First Item") }

      show_page.select_action(first_item, "Move to backlog")

      expect(page).to have_current_path(project_meeting_path(project, meeting), ignore_query: true)
      expect_flash(message: "Agenda item moved to the backlog")
    end
  end

  context "as a user without manage_agendas permission" do
    before { login_as viewer }

    it "can present but is not offered the move actions" do
      visit_presentation
      expect(page).to have_text("First Item")

      show_page.open_menu(first_item) do
        expect(page).to have_no_text("Move to backlog")
        expect(page).to have_no_text("Move to next meeting")
        expect(page).to have_no_text("Move")
      end
    end
  end
end
