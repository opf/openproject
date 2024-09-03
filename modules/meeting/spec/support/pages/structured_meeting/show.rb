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

require_relative "../meetings/show"

module Pages::StructuredMeeting
  class Show < ::Pages::Meetings::Show
    include ::Components::Autocompleter::NgSelectAutocompleteHelpers

    def expect_empty
      expect(page).to have_no_css('[id^="meeting-agenda-items-item-component"]')
    end

    def trigger_dropdown_menu_item(name)
      click_link_or_button "op-meetings-header-action-trigger"
      click_link_or_button name
    end

    def trigger_change_poll
      script = <<~JS
        // Remove flashes from the page to prevent race conditions
        document.querySelectorAll('.op-toast--wrapper').forEach((el) => el.remove());
        var target = document.querySelector('[data-test-selector="meeting-page-header"]');
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

      in_agenda_form do
        yield
        click_on("Save") if save
      end
    end

    def expect_no_add_form
      expect(page).not_to have_test_selector("#meeting-agenda-items-form-component")
    end

    def add_agenda_item_to_section(section:, type: MeetingAgendaItem, save: true, &)
      select_section_action(section, type.model_name.human)

      within("#meeting-sections-show-component-#{section.id}") do
        in_agenda_form do
          yield
          click_on("Save") if save
        end
      end
    end

    def cancel_edit_form(item)
      in_edit_form(item) do
        click_on I18n.t(:button_cancel)
        expect(page).to have_no_link I18n.t(:button_cancel)
      end
    end

    def in_edit_form(item, &)
      page.within("#meeting-agenda-items-item-component-#{item.id}", &)
    end

    def in_agenda_form(&)
      page.within("#meeting-agenda-items-form-component", &)
    end

    def assert_agenda_order!(*titles)
      retry_block do
        found = page.all(:test_id, "op-meeting-agenda-title").map(&:text)
        raise "Expected order of agenda items #{titles.inspect}, but found #{found.inspect}" if titles != found
      end
    end

    def remove_agenda_item(item)
      accept_confirm(I18n.t("text_are_you_sure")) do
        action = item.work_package ? I18n.t(:label_agenda_item_remove) : I18n.t(:button_delete)
        select_action(item, action)
      end

      title = item.work_package ? item.work_package.subject : item.title
      expect_no_agenda_item(title:)
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
        expect(page).to have_css("#meeting-agenda-items-item-component-#{item.id}", text: item.work_package.subject)
      end
    end

    def expect_agenda_author(name)
      expect(page).to have_test_selector("op-principal", text: name)
    end

    def expect_undisclosed_agenda_link(item)
      expect(page).to have_css("#meeting-agenda-items-item-component-#{item.id}",
                               text: I18n.t(:label_agenda_item_undisclosed_wp, id: item.work_package_id))
    end

    def expect_no_agenda_item(title:)
      expect(page).not_to have_test_selector("op-meeting-agenda-title", text: title)
    end

    def select_action(item, action)
      retry_block do
        page.within("#meeting-agenda-items-item-component-#{item.id}") do
          page.find_test_selector("op-meeting-agenda-actions").click
        end
        page.find(".Overlay")
      end

      page.within(".Overlay") do
        click_on action
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

    def edit_agenda_item(item, &)
      select_action item, "Edit"
      expect_item_edit_form(item)
      page.within("#meeting-agenda-items-form-component-#{item.id}", &)
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
      page.within("#meeting-agenda-items-form-component-#{item.id}") do
        expect(page).to have_css(".FormControl-inlineValidation", text:)
      end
    end

    def clear_item_edit_work_package_title
      ng_select_clear page.find(".op-meeting-agenda-item-form--title")
      expect(page).to have_css(".ng-input  ", value: nil)
    end

    def open_participant_form
      page.find_test_selector("manage-participants-button").click
      expect(page).to have_css("#edit-participants-dialog")
    end

    def in_participant_form(&)
      page.within("#edit-participants-dialog", &)
    end

    def expect_participant(participant, invited: false, attended: false, editable: true)
      expect(page).to have_text(participant.name)
      expect(page).to have_field(id: "checkbox_invited_#{participant.id}", checked: invited, disabled: !editable)
      expect(page).to have_field(id: "checkbox_attended_#{participant.id}", checked: attended, disabled: !editable)
    end

    def invite_participant(participant)
      check(id: "checkbox_invited_#{participant.id}")
    end

    def expect_available_participants(count:)
      expect(page).to have_link(class: "op-principal--name", count:)
    end

    def close_meeting
      click_on("Close meeting")
      expect(page).to have_link("Reopen meeting")
    end

    def reopen_meeting
      click_on("Reopen meeting")
      expect(page).to have_link("Close meeting")
    end

    def close_dialog
      click_on(class: "Overlay-closeButton")
    end

    def meeting_details_container
      find_by_id("meetings-side-panel-details-component")
    end

    def in_latest_section_form(&)
      page.within(all(".op-meeting-section-container").last, &)
    end

    def add_section(&)
      page.within("#meeting-agenda-items-new-button-component") do
        click_on I18n.t(:button_add)
        click_on "Section"
        # wait for the disabled button, indicating the turbo streams are applied
        expect(page).to have_css("#meeting-agenda-items-new-button-component button[disabled='disabled']")
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
      select_section_action(section, "Edit")

      page.within_test_selector("meeting-section-header-container-#{section.id}", &)
    end

    def remove_section(section)
      accept_confirm do
        select_section_action(section, "Delete")
      end
    end
  end
end
