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

require_relative "../support/pages/meetings/show"
require_relative "../support/pages/recurring_meeting/show"

RSpec.describe "Move agenda items to section", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create :user,
           member_with_permissions: { project => %i[view_meetings manage_agendas] }
  end
  shared_let(:reader) do
    create :user,
           member_with_permissions: { project => %i[view_meetings] }
  end

  let(:current_user) { user }

  before do
    login_as current_user
  end

  after do
    travel_back
  end

  describe "for one-time meetings" do
    shared_let(:meeting) do
      create :meeting,
             project:,
             author: user,
             state: :in_progress
    end

    let(:show_page) { Pages::Meetings::Show.new(meeting) }

    context "when meeting has multiple sections" do
      let!(:section1) { create(:meeting_section, meeting:, title: "Section 1") }
      let!(:section2) { create(:meeting_section, meeting:, title: "Section 2") }
      let!(:section3) { create(:meeting_section, meeting:, title: "Section 3") }
      let!(:agenda_item) { create(:meeting_agenda_item, meeting:, meeting_section: section1, title: "Item to move") }

      it "allows moving an item to another section" do
        show_page.visit!
        show_page.expect_agenda_item_in_section(title: "Item to move", section: section1)

        show_page.select_action(agenda_item, I18n.t(:label_agenda_item_move_to_section))

        expect(page).to have_css("#move-to-section-dialog")
        expect(page).to have_text("Move to section")

        within("#move-to-section-dialog") do
          select_autocomplete page.find("opce-autocompleter"),
                              query: "Section 2",
                              select_text: "Section 2",
                              results_selector: "#move-to-section-dialog"
          click_button "Save"
        end

        show_page.expect_no_agenda_item_in_section(title: "Item to move", section: section1)
        show_page.expect_agenda_item_in_section(title: "Item to move", section: section2)
      end

      it "shows a confirmation dialog when moving items with unsaved changes" do
        another_item = create(:meeting_agenda_item, meeting:, meeting_section: section1, title: "Another item")
        show_page.visit!

        show_page.edit_agenda_item(another_item, save: false) do
          fill_in "Title", with: "Unsaved edit"
        end

        dismiss_confirm do
          show_page.select_action(agenda_item, I18n.t(:label_agenda_item_move_to_section))
        end

        show_page.expect_item_edit_form(another_item, visible: true)
      end

      it "doesn't show the current section in the options list" do
        show_page.visit!
        show_page.expect_agenda_item_in_section(title: "Item to move", section: section1)

        show_page.select_action(agenda_item, I18n.t(:label_agenda_item_move_to_section))

        expect(page).to have_css("#move-to-section-dialog")

        within("#move-to-section-dialog") do
          autocompleter = page.find("opce-autocompleter")
          search_autocomplete autocompleter,
                              query: "",
                              results_selector: "#move-to-section-dialog"

          expect(page).to have_css(".ng-option", text: "Section 2")
          expect(page).to have_css(".ng-option", text: "Section 3")
          expect(page).to have_css(".ng-option", text: "Agenda backlog")

          expect(page).to have_no_css(".ng-option", text: "Section 1")
        end
      end

      it "preserves backlog collapsed state when moving items between sections" do
        show_page.visit!

        # Set state to opposite of default
        show_page.click_on_backlog
        show_page.expect_backlog collapsed: false

        show_page.select_action(agenda_item, I18n.t(:label_agenda_item_move_to_section))

        within("#move-to-section-dialog") do
          select_autocomplete page.find("opce-autocompleter"),
                              query: "Section 3",
                              select_text: "Section 3",
                              results_selector: "#move-to-section-dialog"
          click_button "Save"
        end

        show_page.expect_backlog collapsed: false
      end

      it "allows moving items from backlog to a specific section" do
        backlog_item = create(:meeting_agenda_item, meeting:, meeting_section: meeting.backlog, title: "Backlog item")

        show_page.visit!
        show_page.click_on_backlog
        show_page.within_backlog do
          show_page.expect_agenda_item(title: "Backlog item")
        end

        show_page.select_action(backlog_item, I18n.t(:label_agenda_item_move_to_section))

        within("#move-to-section-dialog") do
          select_autocomplete page.find("opce-autocompleter"),
                              query: "Section 2",
                              select_text: "Section 2",
                              results_selector: "#move-to-section-dialog"
          click_button "Save"
        end

        show_page.within_backlog do
          show_page.expect_no_agenda_item(title: "Backlog item")
        end
        show_page.expect_agenda_item_in_section(title: "Backlog item", section: section2)
      end

      context "with view permission only" do
        let(:current_user) { reader }

        it "does not show the move to section option" do
          show_page.visit!
          show_page.expect_agenda_item(title: "Item to move")

          show_page.open_menu(agenda_item) do
            expect(page).to have_no_text("Move to section")
          end
        end
      end
    end

    context "when meeting has only one section" do
      let!(:section1) { create(:meeting_section, meeting:, title: "Only Section") }
      let!(:agenda_item) { create(:meeting_agenda_item, meeting:, meeting_section: section1, title: "Item") }

      it "shows 'Move to current meeting' instead of 'Move to section' for backlog items" do
        backlog_item = create(:meeting_agenda_item, meeting:, meeting_section: meeting.backlog, title: "Backlog item")

        show_page.visit!
        show_page.click_on_backlog

        show_page.open_menu(backlog_item) do
          click_on "Move"
          expect(page).to have_css(".ActionListItem-label", text: "Move to current meeting")
          expect(page).to have_no_css(".ActionListItem-label", text: "Move to section")
        end
      end

      it "does not show 'Move to section' for regular agenda items" do
        show_page.visit!

        show_page.open_menu(agenda_item) do
          click_on "Move"
          expect(page).to have_no_text("Move to section")
        end
      end
    end

    context "when meeting has no sections" do
      let!(:agenda_item) { create(:meeting_agenda_item, meeting:, title: "Item") }

      it "shows 'Move to current meeting' instead of 'Move to section' for backlog items" do
        backlog_item = create(:meeting_agenda_item, meeting:, meeting_section: meeting.backlog, title: "Backlog item")

        show_page.visit!
        show_page.click_on_backlog

        show_page.open_menu(backlog_item) do
          click_on "Move"
          expect(page).to have_css(".ActionListItem-label", text: "Move to current meeting")
          expect(page).to have_no_css(".ActionListItem-label", text: "Move to section")
        end
      end

      it "does not show 'Move to section' for regular agenda items" do
        show_page.visit!

        show_page.open_menu(agenda_item) do
          click_on "Move"
          expect(page).to have_no_text("Move to section")
        end
      end
    end
  end

  describe "for recurring meetings" do
    shared_let(:recurring_meeting) do
      create :recurring_meeting,
             :skip_validations,
             project:,
             start_time: "2024-12-31T13:30:00Z",
             frequency: "daily",
             end_after: "specific_date",
             end_date: "2025-01-03",
             author: user
    end

    let(:first_occurrence) { recurring_meeting.meetings.where(template: false).first }
    let(:first_occurrence_page) { Pages::Meetings::Show.new(first_occurrence) }

    before do
      travel_to(Date.new(2024, 12, 30))

      first_occurrence_time = recurring_meeting.first_occurrence.to_time
      RecurringMeetings::InitNextOccurrenceJob.perform_now(recurring_meeting, first_occurrence_time)

      first_occurrence.update(state: :in_progress)
    end

    context "when occurrence has multiple sections" do
      let!(:section1) { create(:meeting_section, meeting: first_occurrence, title: "Occurrence section 1") }
      let!(:section2) { create(:meeting_section, meeting: first_occurrence, title: "Occurrence section 2") }
      let!(:agenda_item) do
        create(:meeting_agenda_item, meeting: first_occurrence, meeting_section: section1, title: "Occurrence item")
      end

      it "allows moving items from series backlog to a specific section" do
        backlog_item = create(:meeting_agenda_item,
                              meeting: recurring_meeting.template,
                              meeting_section: recurring_meeting.template.backlog,
                              title: "Series backlog item")

        first_occurrence_page.visit!
        first_occurrence_page.click_on_backlog
        first_occurrence_page.select_action(backlog_item, I18n.t(:label_agenda_item_move_to_section))

        within("#move-to-section-dialog") do
          select_autocomplete page.find("opce-autocompleter"),
                              query: "Occurrence section 1",
                              select_text: "Occurrence section 1",
                              results_selector: "#move-to-section-dialog"
          click_button "Save"
        end

        first_occurrence_page.within_backlog do
          first_occurrence_page.expect_no_agenda_item(title: "Series backlog item")
        end
        first_occurrence_page.expect_agenda_item_in_section(title: "Series backlog item", section: section1)
      end

      it "allows moving items from section to series backlog preserving collapsed state" do
        first_occurrence_page.visit!

        first_occurrence_page.click_on_backlog
        first_occurrence_page.expect_series_backlog collapsed: false

        first_occurrence_page.select_action(agenda_item, I18n.t(:label_agenda_item_move_to_section))

        within("#move-to-section-dialog") do
          select_autocomplete page.find("opce-autocompleter"),
                              query: "Series backlog",
                              select_text: "Series backlog",
                              results_selector: "#move-to-section-dialog"
          click_button "Save"
        end

        first_occurrence_page.expect_series_backlog collapsed: false
        first_occurrence_page.within_backlog do
          first_occurrence_page.expect_agenda_item(title: "Occurrence item")
        end
        first_occurrence_page.expect_no_agenda_item_in_section(title: "Occurrence item", section: section1)
      end

      it "preserves backlog collapsed state when moving items between sections" do
        first_occurrence_page.visit!

        first_occurrence_page.click_on_backlog
        first_occurrence_page.expect_series_backlog collapsed: false

        first_occurrence_page.select_action(agenda_item, I18n.t(:label_agenda_item_move_to_section))

        within("#move-to-section-dialog") do
          select_autocomplete page.find("opce-autocompleter"),
                              query: "Occurrence section 2",
                              select_text: "Occurrence section 2",
                              results_selector: "#move-to-section-dialog"
          click_button "Save"
        end

        first_occurrence_page.expect_series_backlog collapsed: false
      end

      it "doesn't show template sections when moving from series backlog (Bug #68649)" do
        template = recurring_meeting.template
        create(:meeting_section, meeting: template, title: "Template section 1")
        create(:meeting_section, meeting: template, title: "Template section 2")

        backlog_item = create(:meeting_agenda_item,
                              meeting: template,
                              meeting_section: template.backlog,
                              title: "Series backlog item")

        first_occurrence_page.visit!
        first_occurrence_page.click_on_backlog
        first_occurrence_page.select_action(backlog_item, I18n.t(:label_agenda_item_move_to_section))

        expect(page).to have_css("#move-to-section-dialog")

        within("#move-to-section-dialog") do
          autocompleter = page.find("opce-autocompleter")
          search_autocomplete autocompleter,
                              query: "",
                              results_selector: "#move-to-section-dialog"

          expect(page).to have_css(".ng-option", text: "Occurrence section 1")
          expect(page).to have_css(".ng-option", text: "Occurrence section 2")

          expect(page).to have_no_css(".ng-option", text: "Template section 1")
          expect(page).to have_no_css(".ng-option", text: "Template section 2")

          expect(page).to have_no_css(".ng-option", text: "Series backlog")
        end
      end
    end

    context "when template has multiple sections" do
      let(:template) { recurring_meeting.template }
      let!(:section1) { create(:meeting_section, meeting: template, title: "Template section 1") }
      let!(:section2) { create(:meeting_section, meeting: template, title: "Template section 2") }
      let!(:agenda_item) do
        create(:meeting_agenda_item, meeting: template, meeting_section: section1, title: "Template item")
      end
      let(:template_page) { Pages::Meetings::Show.new(template) }

      it "allows moving items from one section to another in templates (Regression #68426)" do
        template_page.visit!
        template_page.select_action(agenda_item, I18n.t(:label_agenda_item_move_to_section))

        within("#move-to-section-dialog") do
          select_autocomplete page.find("opce-autocompleter"),
                              query: "Template section 2",
                              select_text: "Template section 2",
                              results_selector: "#move-to-section-dialog"
          click_button "Save"
        end

        template_page.expect_agenda_item_in_section(title: agenda_item.title, section: section2)
        template_page.expect_no_agenda_item_in_section(title: agenda_item.title, section: section1)
      end
    end
  end
end
