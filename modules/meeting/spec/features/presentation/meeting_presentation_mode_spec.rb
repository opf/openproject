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

require_relative "../../support/pages/meetings/show"

RSpec.describe "Meeting Presentation Mode", :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create :user,
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings edit_meetings manage_agendas manage_outcomes] }
  end
  shared_let(:meeting) do
    create :meeting,
           project:,
           title: "Sprint Planning",
           start_time: "2025-10-31T10:00:00Z",
           duration: 1.5,
           state: :open,
           author: user
  end

  shared_let(:first_meeting_section) { create(:meeting_section, meeting:, title: "Blockers", position: 1) }
  shared_let(:second_meeting_section) { create(:meeting_section, meeting:, title: "Other topics", position: 2) }
  shared_let(:first_agenda_item) do
    create(:meeting_agenda_item,
           meeting:,
           meeting_section: first_meeting_section,
           title: "First Item",
           position: 1)
  end
  shared_let(:second_agenda_item) do
    create(:meeting_agenda_item,
           meeting:,
           meeting_section: first_meeting_section,
           title: "Second Item",
           position: 2)
  end

  shared_let(:third_agenda_item) do
    create(:meeting_agenda_item,
           meeting:,
           meeting_section: second_meeting_section,
           title: "Third Item",
           position: 1)
  end

  let(:show_page) { Pages::Meetings::Show.new(meeting) }
  let(:editor) { Components::WysiwygEditor.new "#op-meeting-presentation-content", "opce-ckeditor-augmented-textarea" }

  def outcome_field_for(agenda_item)
    TextEditorField.new(page, "Outcome", selector: test_selector("meeting-outcome-input-for-#{agenda_item.id}"))
  end

  before do
    login_as user
  end

  it "allows full presentation workflow: start, navigate, edit, manage outcomes, and close" do
    # 0. Start presentation from show page
    show_page.visit!
    expect(page).to have_text("Sprint Planning")
    expect(page).to have_text("First Item")
    expect(page).to have_text("Second Item")

    within("#meetings-header-component") do
      expect(page).to have_link("Present")
      click_link_or_button "Present"
    end

    # Verify we're in presentation mode
    expect(page).to have_current_path(project_meeting_presentation_path(project, meeting), ignore_query: true)
    expect(page).to have_css(".op-meeting-presentation")
    expect(page).to have_text("Sprint Planning")
    expect(page).to have_text("First Item")
    expect(page).to have_link("Next")
    expect(page).to have_button("Previous", disabled: true)
    expect(page).to have_text("1 of 3")

    # Presenting puts the meeting in 'in_progress' state
    meeting.reload
    expect(meeting.state).to eq("in_progress")

    within_test_selector("meeting-presentation-header") do
      expect(page).to have_text("Blockers")
    end

    within_test_selector("meeting-presentation-footer") do
      expect(page).to have_text("Second Item")
      expect(page).to have_no_text("Blockers")
      expect(page).to have_no_text("Other topics")
    end

    # 1. Navigate between agenda items
    click_link_or_button "Next"

    within_test_selector("meeting-presentation-agenda-item") do
      expect(page).to have_text("Second Item")
      expect(page).to have_no_text("First Item")
    end

    within_test_selector("meeting-presentation-footer") do
      expect(page).to have_text("First Item")
      expect(page).to have_text("Third Item")
      expect(page).to have_no_text("Blockers")
      expect(page).to have_text("Other topics")
      expect(page).to have_link("Previous")
      expect(page).to have_link("Next")
    end

    expect(page).to have_text("2 of 3")

    # 1. Navigate between agenda items
    click_link_or_button "Next"

    within_test_selector("meeting-presentation-agenda-item") do
      expect(page).to have_text("Third Item")
      expect(page).to have_no_text("First Item")
      expect(page).to have_no_text("Second Item")
    end

    # On third item, footer shows second item and first item
    within_test_selector("meeting-presentation-footer") do
      # Shows second item with section
      expect(page).to have_text("Second Item")
      expect(page).to have_text("Blockers")

      # Doesn't show first item or current section
      expect(page).to have_no_text("First Item")
      expect(page).to have_no_text("Other topics")
      expect(page).to have_link("Previous")
      expect(page).to have_button("Next", disabled: true)
    end

    expect(page).to have_text("3 of 3")

    click_link_or_button "Previous"
    expect(page).to have_text("2 of 3")

    click_link_or_button "Previous"
    expect(page).to have_text("1 of 3")
    expect(page).to have_button("Previous", disabled: true)

    # 2. Edit an agenda item (add notes)
    item = MeetingAgendaItem.find(first_agenda_item.id)

    # Find and click the edit action for notes and add a body (was empty before)
    show_page.select_action(item, "Edit")
    editor.set_markdown "# Hello there"

    show_page.in_edit_form(item) do
      click_link_or_button "Save"
    end

    # Wait for the edit form to close and the notes to be visible
    within_test_selector("meeting-presentation-agenda-item") do
      expect(page).to have_text("First Item")
      expect(page).to have_text("Hello there")
    end

    # 3. Manage outcomes: add, edit, and delete
    # Add an outcome
    show_page.add_outcome_from_menu(item) do
      field = outcome_field_for(item)
      field.expect_active!
      field.set_value "Team agreed on approach"
      click_link_or_button "Save"
    end

    show_page.in_outcome_component(item) do
      show_page.expect_outcome "Team agreed on approach"

      show_page.select_outcome_action "Edit outcome"
      field = outcome_field_for(item)
      field.expect_active!
      field.set_value "Updated outcome"
      click_link_or_button "Save"

      show_page.expect_outcome "Updated outcome"
    end

    # Delete the outcome
    show_page.in_outcome_component(item) do
      show_page.expect_outcome "Updated outcome"
      accept_confirm(I18n.t(:text_are_you_sure)) do
        show_page.select_outcome_action "Remove outcome"
      end

      show_page.expect_no_outcome "Updated outcome"
    end

    # 4. Close the presentation
    page.find_test_selector("exit-presentation-button").click

    # Verify we're back on the show page
    expect(page).to have_current_path(project_meeting_path(project, meeting), ignore_query: true)
  end

  it "automatically refreshes when things get updated" do
    visit project_meeting_presentation_path(project, meeting)
    expect(page).to have_css(".op-meeting-presentation")
    expect(page).to have_text("Sprint Planning")
    expect(page).to have_text("First Item")

    # In the background, update the first agenda item
    MeetingAgendaItems::UpdateService
      .new(model: first_agenda_item, user: User.system)
      .call(title: "Updated Item")
      .on_failure { |result| raise "Failed to update agenda item in background: #{result.errors.full_messages}" }

    # In the background, delete the second item
    # so that the "new" second item is now the third one
    MeetingAgendaItems::DeleteService
      .new(model: second_agenda_item, user: User.system)
      .call
      .on_failure { |result| raise "Failed to update agenda item in background: #{result.errors.full_messages}" }

    # Wait for the changes to appear
    expect(page).to have_text("Updated Item", wait: 10)
    expect(page).to have_no_text("Second Item")

    # On third item, footer shows second item and first item
    within_test_selector("meeting-presentation-footer") do
      # Shows second item with section
      expect(page).to have_text("Third Item")
      expect(page).to have_text("Other topics")
      expect(page).to have_no_text("Second Item")
      expect(page).to have_no_text("Blockers")
    end
  end

  context "with an empty meeting" do
    let(:meeting) do
      create :meeting,
             project:,
             title: "Empty meeting",
             start_time: "2025-10-31T10:00:00Z",
             state: :in_progress,
             author: user
    end

    it "does not show the present button" do
      show_page.visit!

      within("#meetings-header-component") do
        expect(page).to have_no_link("Present")
      end

      # When visiting the presentation mode directly
      visit project_meeting_presentation_path(project, meeting)

      expect_flash(type: :warning, message: "There are no agenda items to present.")
    end
  end

  context "with a templated meeting" do
    let!(:series) { create(:recurring_meeting, project:) }
    let(:meeting) { series.template }

    it "does not show the present button" do
      show_page.visit!

      within("#meetings-header-component") do
        expect(page).to have_no_link("Present")
      end
    end
  end

  context "with a draft meeting" do
    let!(:meeting) { create(:meeting, project:, state: :draft) }
    let!(:agenda_item) { create(:meeting_agenda_item, meeting:) }

    it "does not show the present button even with agenda items" do
      show_page.visit!

      within("#meetings-header-component") do
        expect(page).to have_no_link("Present")
      end
    end
  end
end
