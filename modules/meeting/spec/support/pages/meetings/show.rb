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

require_relative "base"

module Pages::Meetings
  class Show < Base
    include ::Components::Autocompleter::NgSelectAutocompleteHelpers

    attr_accessor :meeting

    def initialize(meeting)
      self.meeting = meeting

      super(meeting.project)
    end

    def expect_no_invited
      expect(page)
        .to have_content("#{Meeting.human_attribute_name(:participants_invited)}: -")
    end

    def expect_no_attended
      expect(page)
        .to have_content("#{Meeting.human_attribute_name(:participants_attended)}: -")
    end

    def expect_invited(*users)
      users.each do |user|
        within(meeting_details_container) do
          expect(page)
            .to have_link(user.name)
        end
      end
    end

    def expect_uninvited(*users)
      users.each do |user|
        within(meeting_details_container) do
          expect(page)
            .to have_no_link(user.name)
        end
      end
    end

    def expect_date_time(expected)
      expect(page)
        .to have_content("Start time: #{expected}")
    end

    def expect_link_to_location(location)
      within(meeting_details_container) do
        expect(page).to have_link location
      end
    end

    def expect_plaintext_location(location)
      within(meeting_details_container) do
        expect(page).to have_no_link location
        expect(page).to have_text(location)
      end
    end

    def path
      project_meeting_path(meeting.project, meeting)
    end

    def expect_empty
      expect(page).to have_no_css('[id^="meeting-agenda-items-item-component"]')
    end

    def trigger_dropdown_menu_item(name)
      click_link_or_button "op-meetings-header-action-trigger"
      click_link_or_button name
    end

    def trigger_change_poll
      script = <<~JS
        var target = document.querySelector('#content-wrapper');
        var controller = window.Stimulus.getControllerForElementAndIdentifier(target, 'poll-for-changes')
        controller.triggerTurboStream();
      JS

      page.execute_script(script)
    end

    def add_agenda_item(type: MeetingAgendaItem, save: true, &)
      page.within("#meeting-agenda-items-new-button-component") do
        click_on I18n.t(:button_add)
        click_on type.model_name.human
      end

      created_id = nil
      in_agenda_form do
        yield
        created_id = click_save_and_wait_for_agenda_item_creation if save
      end
      expect(page).to have_css("#meeting-agenda-item-#{created_id}") if created_id
    end

    def expect_modal(...)
      Components::Common::Modal.new.expect_modal(...)
    end

    def expect_no_add_form
      expect(page).not_to have_test_selector("#meeting-agenda-items-form-component")
    end

    def add_agenda_item_to_section(section:, type: MeetingAgendaItem, save: true, &)
      select_section_action(section, "Add #{type.model_name.human.downcase}")

      within("#meeting-sections-show-component-#{section.id}") do
        created_id = nil
        in_agenda_form do
          yield
          created_id = click_save_and_wait_for_agenda_item_creation if save
        end
        expect(page).to have_css("#meeting-agenda-item-#{created_id}") if created_id
      end
    end

    def cancel_edit_form(item)
      in_edit_form(item) do
        click_on I18n.t(:button_cancel)
        expect(page).to have_no_link I18n.t(:button_cancel)
      end
    end

    def in_edit_form(item, &)
      page.within("#meeting-agenda-item-#{item.id}", &)
    end

    def in_agenda_form(&)
      page.within("#meeting-agenda-items-form-component-new", &)
    end

    def assert_agenda_order!(*titles)
      wait_for_network_idle

      retry_block do
        found = page.all(:test_id, "op-meeting-agenda-title").map(&:text)
        raise "Expected order of agenda items #{titles.inspect}, but found #{found.inspect}" if titles != found
      end
    end

    def remove_agenda_item(item)
      accept_confirm(I18n.t("text_are_you_sure")) do
        action = item.work_package ? wp_agenda_item_delete_label(item) : I18n.t(:button_delete)
        select_action(item, action)
      end

      title = item.work_package ? item.work_package.subject : item.title
      expect_no_agenda_item(title:)
    end

    def wp_agenda_item_delete_label(item)
      item.in_backlog? ? I18n.t(:label_agenda_item_remove_from_backlog) : I18n.t(:label_agenda_item_remove_from_agenda)
    end

    def expect_agenda_item(title:)
      expect(page).to have_test_selector("op-meeting-agenda-title", text: title)
    end

    def expect_agenda_item_in_section(title:, section:)
      within("#meeting-sections-show-component-#{section.id}") do
        expect_agenda_item(title:)
      end
    end

    def expect_agenda_link(item)
      if item.is_a?(WorkPackage)
        expect(page).to have_css("[id^='meeting-agenda-items-item-component-']", text: item.subject)
      else
        expect(page).to have_css("#meeting-agenda-item-#{item.id}", text: item.work_package.subject)
      end
    end

    def expect_agenda_author(name)
      expect(page).to have_test_selector("op-principal", text: name)
    end

    def expect_undisclosed_agenda_link(item)
      expect(page).to have_css("#meeting-agenda-item-#{item.id}",
                               text: I18n.t(:label_agenda_item_undisclosed_wp, id: item.work_package_id))
    end

    def expect_no_agenda_item(title:)
      expect(page).not_to have_test_selector("op-meeting-agenda-title", text: title)
    end

    def expect_no_agenda_item_in_section(title:, section:)
      within("#meeting-sections-show-component-#{section.id}") do
        expect_no_agenda_item(title:)
      end
    end

    def expect_agenda_action_menu(item)
      expect(page)
        .to have_css("#meeting-agenda-item-#{item.id} #{test_selector('op-meeting-agenda-actions')}")
    end

    def expect_no_agenda_action_menu(item)
      expect(page)
        .to have_no_css("#meeting-agenda-item-#{item.id} #{test_selector('op-meeting-agenda-actions')}")
    end

    def select_action(item, action)
      open_menu(item) do
        if action.downcase.include?("move")
          click_on "Move"
        elsif action.downcase.include?("outcome")
          click_on "Add outcome"
        end
        click_on action
      end
    end

    def move_item_to_next_meeting(item)
      select_action(item, "Move to next meeting")
      expect_modal("Move to next meeting?")

      retry_block do
        page.within_modal "Move to next meeting?" do
          click_on "Move"
        end
      end
    end

    def duplicate_item_in_next_meeting(item)
      open_menu(item) do
        click_on "Duplicate"
        click_on "Duplicate in next meeting"
      end
      expect_modal("Duplicate in next meeting?")

      retry_block do
        page.within_modal "Duplicate in next meeting?" do
          click_on "Duplicate"
        end
      end
    end

    def open_menu(item, &)
      retry_block do
        page.within("#meeting-agenda-item-#{item.id}") do
          page.find_test_selector("op-meeting-agenda-actions").click
        end
        page.find(".Overlay")
        page.within(".Overlay", &)
      end
    end

    def select_outcome_action(action)
      retry_block do
        page.find_test_selector("op-meeting-outcome-actions").click
        page.find(".Overlay")
      end

      page.within(".Overlay") do
        click_on action
      end
    end

    def expect_no_outcome_actions
      expect(page).to have_no_css("op-meeting-outcome-actions")
    end

    def expect_no_outcome_action(item)
      retry_block do
        page.within("#meeting-agenda-item-#{item.id}") do
          page.find_test_selector("op-meeting-agenda-actions").trigger("click")
        end
        page.find(".Overlay")
      end

      page.within(".Overlay") do
        expect(page).to have_no_text("Add outcome")
      end
    end

    def select_section_action(section, action)
      retry_block do
        click_on_section_menu(section)
        page.find(".Overlay")
      end

      page.within(".Overlay") do
        click_on action
      end
    end

    def click_on_section_menu(section)
      page.within_test_selector("meeting-section-header-container-#{section.id}") do
        page.find_test_selector("meeting-section-action-menu").click
      end
    end

    def in_outcome_component(item, &)
      page.within("#meeting-agenda-items-outcomes-wrapper-component-#{item.id}", &)
    end

    def add_outcome(item, &)
      page.within("#meeting-agenda-items-outcomes-new-button-component-#{item.id}") do
        click_on "Outcome"
      end
      expect(page).to have_text("Write outcome", wait: 2)
      page.find("a", text: "Write outcome").click
      expect_outcome_form(item)
      page.within("#meeting-agenda-items-outcomes-input-component-#{item.id}", &)
    end

    def add_outcome_from_menu(item, &)
      open_menu(item) do
        click_on "Add outcome"
        expect(page).to have_text("Write outcome", wait: 2)
        click_on "Write outcome"
      end
      expect_outcome_form(item)
      page.within("#meeting-agenda-items-outcomes-input-component-#{item.id}", &)
    end

    def expect_outcome_form(item)
      expect(page)
        .to have_css("#meeting-agenda-items-outcomes-input-component-#{item.id}")
    end

    def expect_outcome(text)
      expect(page).to have_css(".op-meeting-outcome-notes--content", text:)
    end

    def expect_no_outcome(text)
      expect(page).to have_no_css(".op-meeting-outcome-notes--content", text:)
    end

    def expect_no_outcome_button
      expect(page).to have_no_css("op-meeting-outcome--button")
    end

    def expect_backlog(collapsed:)
      expect(page).to have_css(".CollapsibleHeader", text: I18n.t("label_agenda_backlog"))

      if collapsed
        expect(page).to have_css(".CollapsibleHeader[data-collapsed]")
        expect(page).to have_no_text(I18n.t("text_agenda_backlog"))
      else
        expect(page).to have_no_css(".CollapsibleHeader[data-collapsed]")
        expect(page).to have_text(I18n.t("text_agenda_backlog"))
      end
    end

    def expect_series_backlog(collapsed:)
      expect(page).to have_css(".CollapsibleHeader", text: I18n.t("label_series_backlog"))

      if collapsed
        expect(page).to have_css(".CollapsibleHeader[data-collapsed]")
        expect(page).to have_no_text(I18n.t("text_series_backlog"))
      else
        expect(page).to have_no_css(".CollapsibleHeader[data-collapsed]")
        expect(page).to have_text(I18n.t("text_series_backlog"))
      end
    end

    def expect_backlog_count(count)
      within("#meeting-sections-backlogs-container-component") do
        expect(page).to have_css(".Counter", text: count)
      end
    end

    def expect_no_backlog
      expect(page).to have_no_css(".CollapsibleHeader")
    end

    def expect_empty_backlog
      within_backlog do
        retry_block do
          expect(page).to have_text("Drag items here or create a new one")
          expect(page).to have_button("Add")
        end
      end
    end

    def add_agenda_item_to_backlog(type: MeetingAgendaItem, &)
      select_backlog_action("Add #{type.model_name.human.downcase}")

      within("#meeting-sections-backlogs-container-component") do
        created_id = nil
        in_agenda_form do
          yield
          created_id = click_save_and_wait_for_agenda_item_creation
        end
        expect(page).to have_css("#meeting-agenda-item-#{created_id}")
      end
    end

    # Clicks "Save" button and waits until the number of agenda items in the database has
    # changed.
    def click_save_and_wait_for_agenda_item_creation
      initial_db_items_count = MeetingAgendaItem.count
      click_on("Save")

      # wait for db save
      wait_for { MeetingAgendaItem.count }.not_to eq(initial_db_items_count)

      # return created item id so that caller can wait for it (can't do it here
      # because of being "in_agenda_form" scope)
      MeetingAgendaItem.maximum(:id)
    end

    # Clicks "Save" button and waits until some agenda items have a different
    # `lock_version` value in the database.
    def click_save_and_wait_for_agenda_item_update
      initial_db_items_versions = MeetingAgendaItem.order(:id).pluck(:lock_version)
      click_on("Save")

      # wait for db save
      wait_for { MeetingAgendaItem.order(:id).pluck(:lock_version) }.not_to eq(initial_db_items_versions)
    end

    def select_backlog_action(action)
      retry_block do
        click_on_backlog_menu
        page.find(".Overlay")
        page.within(".Overlay") do
          click_on action
        end
      end
    end

    def click_on_backlog_menu
      page.within("#meeting-sections-backlogs-header-component") do
        page.find_test_selector("meeting-section-action-menu").click
      end
    end

    def within_backlog(&)
      page.within("#meeting-sections-backlogs-container-component", &)
    end

    def click_on_backlog
      within_backlog do
        page.find(".CollapsibleHeader").click
      end
    end

    def clear_backlog
      select_backlog_action(I18n.t("label_backlog_clear"))
      expect(page).to have_modal(I18n.t("label_backlog_clear"), wait: 3)
      page.within_modal(I18n.t("label_backlog_clear")) do
        click_on "Clear all"
      end
    end

    def edit_agenda_item(item, save: true, wait_for_reference_update: false, &)
      wait_for_turbo_stream { select_action item, "Edit" }
      expect_item_edit_form(item)
      reference_value = meeting_reference_value
      page.within("#meeting-agenda-items-form-component-#{item.id}") do
        yield
        if save
          click_save_and_wait_for_agenda_item_update
        end
      end

      wait_for_reference_changed(reference_value) if save && wait_for_reference_update
    end

    def expect_item_edit_form(item, visible: true)
      expect(page)
        .to have_conditional_selector(
          visible,
          "#meeting-agenda-items-form-component-#{item.id}"
        )
    end

    def expect_item_edit_title(item, value)
      page.within("#meeting-agenda-items-form-component-#{item.id}") do
        find_field("Title", with: value)
      end
    end

    def expect_item_edit_field_error(item, text)
      # retry because the #meeting-agenda-items-form-component-<id> may not be
      # updated yet and then becomes stale while checking for field error.
      retry_block do
        page.within("#meeting-agenda-items-form-component-#{item.id}") do
          expect(page).to have_css(".FormControl-inlineValidation", text:)
        end
      end
    end

    def clear_item_edit_work_package_title
      ng_select_clear page.find(".op-meeting-agenda-item-form--title")
      expect(page).to have_css(".ng-input  ", value: nil)
    end

    def open_participant_form
      page.find_test_selector("manage-participants-button").click
      retry_block do
        expect_modal("Manage participants")
      end
    end

    def in_participant_form(&)
      page.within_modal("Manage participants", &)
    end

    def expect_participant(participant, attended: false, editable: true)
      expect(page).to have_text(participant.name)

      if !editable
        expect(page).to have_no_selector("[data-test-selector='attendance_button_#{participant.id}']", text: "Attended")
        expect(page).to have_no_selector("[data-test-selector='attendance_button_#{participant.id}']", text: "Mark as attended")

        return
      end

      if attended
        expect(page).to have_css("[data-test-selector='attendance_button_#{participant.id}']", text: "Attended")
      else
        expect(page).to have_css("[data-test-selector='attendance_button_#{participant.id}']", text: "Mark as attended")
      end
    end

    def expect_participant_invited(participant, invited: true)
      expect(page).to have_text(participant.name)
      expect(page).to have_field(id: "checkbox_invited_#{participant.id}", checked: invited)
    end

    def invite_participant(participant)
      id = "checkbox_invited_#{participant.id}"
      retry_block do
        check(id:)
        raise "Expected #{participant.id} to be invited now" unless page.has_checked_field?(id:)
      end
    end

    def toggle_attendance(participant)
      expect(page).to have_text(participant.name)
      click_link_or_button("attendance_button_#{participant.id}")
    end

    def select_participant(participant)
      select_autocomplete page.find('[data-test-selector="participants-dialog-autocomplete"]'),
                          query: participant.firstname,
                          select_text: participant.name,
                          results_selector: "body"

      click_on "Add"
    end

    def uncheck_apply_to_upcoming
      page.find('input[type="checkbox"][name="meeting_participant[apply_to_upcoming]"]').set(false)
    end

    def expect_apply_to_upcoming_checked
      expect(page).to have_checked_field("meeting_participant[apply_to_upcoming]")
    end

    def expect_apply_to_upcoming_unchecked
      expect(page).to have_unchecked_field("meeting_participant[apply_to_upcoming]")
    end

    def expect_no_participant(participant)
      autocomplete = page.find('[data-test-selector="participants-dialog-autocomplete"]')
      search_autocomplete(autocomplete, query: participant.lastname, results_selector: "body")
      expect_no_ng_option(autocomplete, participant.name, results_selector: "body")
    end

    def remove_participant(participant)
      expect(page).to have_text(participant.name)
      click_link_or_button("remove_button_#{participant.id}")
    end

    def expect_available_participants(count:)
      expect(page).to have_link(class: "meeting-participant-user-link", count:)
    end

    def close_meeting
      retry_block do
        click_on("Open")
        page.find(".Overlay")
      end

      page.within(".Overlay") do
        click_on("Closed")
      end
      expect(page).to have_link("Reopen meeting")
    end

    def close_meeting_from_in_progress
      page.within("#meetings-side-panel-state-component") do
        click_on("Close meeting")
      end
    end

    def open_meeting
      page.within("#meetings-side-panel-state-component") do
        click_on("Open meeting")
      end

      expect(page).to have_dialog(I18n.t("text_exit_draft_mode_dialog_title"))
      page.within_dialog(I18n.t("text_exit_draft_mode_dialog_title")) do
        click_on "Open meeting"
      end

      page.within("#meetings-side-panel-state-component") do
        expect(page).to have_link("Start meeting")
      end
    end

    def open_first_meeting
      page.within("#meetings-side-panel-state-component") do
        click_on("Open first meeting")
      end

      expect(page).to have_dialog(I18n.t("text_exit_draft_mode_dialog_template_title"))
      page.within_dialog(I18n.t("text_exit_draft_mode_dialog_template_title")) do
        click_on "Open meeting"
      end
    end

    def start_meeting
      page.within("#meetings-side-panel-state-component") do
        click_on("Start meeting")
        expect(page).to have_link("Close meeting")
      end
    end

    def reopen_meeting
      click_on("Reopen meeting")
      expect(page).to have_link("Start meeting")
    end

    def close_dialog
      click_on(class: "Overlay-closeButton")
    end

    def meeting_details_container
      find_by_id("meetings-side-panel-details-component")
    end

    def in_latest_section_form(&)
      sections = all(".op-meeting-section-container")
      last_except_backlog = sections[-2]
      page.within(last_except_backlog, &)
    end

    def add_section(&)
      retry_block do
        page.within("#meeting-agenda-items-new-button-component") do
          click_on I18n.t(:button_add)
          click_on "Section"
          # wait for the disabled button, indicating the turbo streams are applied
          expect(page).to have_css("#meeting-agenda-items-new-button-component button[disabled='disabled']")
        end
      end

      in_latest_section_form(&)
    end

    def expect_section(title:)
      expect(page).to have_css(".op-meeting-section-container", text: title)
    end

    def expect_no_section(title:)
      expect(page).to have_no_css(".op-meeting-section-container", text: title)
    end

    def expect_section_duration(section:, duration_text:)
      page.within_test_selector("meeting-section-header-container-#{section.id}") do
        expect(page).to have_text(duration_text)
      end
    end

    def edit_section(section, &)
      select_section_action(section, "Rename section")

      page.within_test_selector("meeting-section-header-container-#{section.id}", &)
    end

    def remove_section(section)
      accept_confirm do
        select_section_action(section, "Delete")
      end
    end

    def check_add_section_path(meeting)
      retry_block do
        page.within("#meeting-agenda-items-new-button-component") do
          click_on I18n.t(:button_add)

          add_section_link = find_link("Section")
          url = add_section_link[:href]

          expect(URI.parse(url).path).to eq(project_meeting_sections_path(meeting.project, meeting))
        end
      end
    end

    def expect_backlog_actions(item, series: false)
      open_menu(item) do
        click_on "Move"

        expect(page).to have_css(".ActionListItem-label", text: "Edit")
        expect(page).to have_css(".ActionListItem-label", text: "Add notes")
        expect(page).to have_css(".ActionListItem-label", text: "Move to current meeting")
        expect(page).to have_css(".ActionListItem-label", text: "Delete")

        expect(page).to have_no_css(".ActionListItem-label", text: "Move to backlog")
        expect(page).to have_no_css(".ActionListItem-label", text: "Add outcome")

        if series
          expect(page).to have_no_css(".ActionListItem-label", text: "Move to next meeting")
        end
      end

      page.within("#meeting-agenda-item-#{item.id}") do
        page.find_test_selector("op-meeting-agenda-actions").click
      end
    end

    def expect_non_backlog_actions(item, series: false)
      open_menu(item) do
        click_on "Move"

        expect(page).to have_css(".ActionListItem-label", text: "Move to backlog")
        expect(page).to have_no_css(".ActionListItem-label", text: "Move to current meeting")

        if series
          expect(page).to have_css(".ActionListItem-label", text: "Move to next meeting")
        end
      end

      page.within("#meeting-agenda-item-#{item.id}") do
        page.find_test_selector("op-meeting-agenda-actions").click
      end
    end

    def expect_no_backlog_header_actions
      within_backlog do
        expect { page.find_test_selector("meeting-section-action-menu") }.to raise_error(Capybara::ElementNotFound)
      end
    end

    def expect_blankslate
      expect(page).to have_test_selector("meeting-blankslate")
    end

    def expect_focused_input(input_id)
      retry_block do
        expect(page.evaluate_script("document.activeElement.id")).to eq(input_id)
      end
    end

    # still a bit ambiguous, but better than nothing
    def expect_focused_ckeditor
      retry_block do
        expect(page.evaluate_script("document.activeElement.classList.contains('ck-focused')")).to be true
      end
    end

    def expect_notes(text)
      expect(page).to have_css(".op-meeting-agenda-item--notes", text:)
    end

    def set_start_time(time)
      input = page.find_by_id("meeting_start_time_hour")
      page.execute_script("arguments[0].value = arguments[1]", input.native, time)
      page.execute_script("arguments[0].dispatchEvent(new Event('input'))", input.native)
    end

    def meeting_reference_value
      page_header = page.find("#meetings-header-component page-header")
      page_header["data-reference-value"]
    end

    def wait_for_reference_changed(old_reference_value)
      expect(page).to have_css("#meetings-header-component page-header") do |element|
        element["data-reference-value"] != old_reference_value
      end
    end

    def section_headers
      page.all(".op-meeting-section-container[data-test-selector^='meeting-section-header-container-']")
          .map(&:text)
    end
  end
end
