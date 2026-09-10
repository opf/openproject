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
require_relative "../../support/pages/meetings/index"

RSpec.describe "Meetings CRUD",
               :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           lastname: "First",
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings manage_agendas
                                                    view_work_packages] }).tap do |u|
      u.pref[:time_zone] = "Etc/UTC"

      u.save!
    end
  end
  shared_let(:other_user) do
    create(:user,
           lastname: "Second",
           member_with_permissions: { project => %i[view_meetings view_work_packages] })
  end
  shared_let(:no_member_user) do
    create(:user,
           lastname: "Third")
  end
  shared_let(:work_package) do
    create(:work_package, project:, subject: "Important task")
  end

  let(:current_user) { user }
  let(:meeting) { Meeting.last }
  let(:show_page) { Pages::Meetings::Show.new(meeting) }
  let(:meetings_page) { Pages::Meetings::Index.new(project:) }

  before do |test|
    login_as current_user
    meetings_page.visit!
    expect(page).to have_current_path(meetings_page.path) # rubocop:disable RSpec/ExpectInHook
    meetings_page.click_on "add-meeting-button"
    meetings_page.click_on "One-time"
    meetings_page.set_title "Some title"

    meetings_page.set_start_date "2013-03-28"
    meetings_page.set_start_time "13:30"
    meetings_page.set_duration "1.5"

    if test.metadata[:checked]
      expect(page).to have_unchecked_field "send_notifications" # rubocop:disable RSpec/ExpectInHook
      check "send_notifications"
    end

    meetings_page.click_create
    expect_and_dismiss_flash(type: :success, message: I18n.t(:notice_successful_create))
  end

  it "can create a meeting and add agenda items" do
    # Can add and edit a single item
    show_page.add_agenda_item do
      fill_in "Title", with: "My agenda item"
      fill_in "Duration", with: "25"
    end

    show_page.expect_agenda_item title: "My agenda item"
    item = MeetingAgendaItem.find_by(title: "My agenda item")

    # Can update
    show_page.edit_agenda_item(item) do
      fill_in "Title", with: "Updated title"
    end

    show_page.expect_no_agenda_item title: "My agenda item"
    show_page.expect_agenda_item title: "Updated title"

    # Can add multiple items
    show_page.add_agenda_item do
      fill_in "Title", with: "First"
    end

    show_page.expect_agenda_item title: "Updated title"
    show_page.expect_agenda_item title: "First"

    # Does not add empty form after save
    show_page.expect_no_add_form

    show_page.add_agenda_item do
      fill_in "Title", with: "Second"
    end

    show_page.expect_agenda_item title: "Updated title"
    show_page.expect_agenda_item title: "First"
    show_page.expect_agenda_item title: "Second"

    # Can reorder
    show_page.assert_agenda_order! "Updated title", "First", "Second"

    second = MeetingAgendaItem.find_by!(title: "Second")
    wait_for_turbo_stream { show_page.select_action(second, I18n.t(:label_sort_higher)) }
    show_page.assert_agenda_order! "Updated title", "Second", "First"

    first = MeetingAgendaItem.find_by!(title: "First")
    wait_for_turbo_stream { show_page.select_action(first, I18n.t(:label_sort_highest)) }
    show_page.assert_agenda_order! "First", "Updated title", "Second"

    # Can edit and cancel with escape
    show_page.edit_agenda_item(first, save: false) do
      find_field("Title").send_keys :escape
    end
    show_page.expect_item_edit_form(first, visible: false)

    # Can remove
    show_page.remove_agenda_item first
    show_page.assert_agenda_order! "Updated title", "Second"

    # Can link work packages
    show_page.add_agenda_item(type: WorkPackage) do
      select_autocomplete(find_test_selector("op-agenda-items-wp-autocomplete"),
                          query: "task",
                          results_selector: "body")
    end

    show_page.expect_agenda_link work_package
    wp_item = MeetingAgendaItem.find_by!(work_package_id: work_package.id)
    expect(wp_item).to be_present

    # Can edit and validate a work package item
    show_page.edit_agenda_item(wp_item, save: false) do
      show_page.clear_item_edit_work_package_title
      click_on "Save" # triggers an error
    end

    show_page.expect_item_edit_field_error(wp_item, "Work package can't be blank.")
    show_page.cancel_edit_form(wp_item)

    # Shows a confirmation dialog when trying to reorder while editing an agenda item
    show_page.assert_agenda_order! "Updated title", "Second", "Important task"

    show_page.edit_agenda_item(second, save: false) do
      fill_in "Title", with: "Second edited"
      fill_in_rich_text "Notes", with: "Notes for the agenda item"
    end

    dismiss_confirm do
      show_page.select_action(wp_item, I18n.t(:label_sort_highest))
    end

    show_page.assert_agenda_order! "Updated title", "Important task"
    show_page.expect_item_edit_form(second, visible: true)

    # Accepting the confirmation reorders items and closes the edit state
    wait_for_turbo_stream do
      accept_confirm do
        show_page.select_action(wp_item, I18n.t(:label_sort_highest))
      end
    end

    show_page.assert_agenda_order! "Important task", "Updated title", "Second"
    show_page.expect_item_edit_form(second, visible: false)

    # After accepting the confirmation dialog, subsequent reordering should not show the dialog again
    expect do
      accept_confirm do
        show_page.select_action(second, I18n.t(:label_sort_highest))
      end
    end.to raise_error(Capybara::ModalNotFound)

    # user can see actions
    expect(page).to have_css("#meeting-agenda-items-new-button-component")
    expect(page).to have_test_selector("op-meeting-agenda-actions", count: 3)

    # other_use can view and copy links, but not edit or move
    login_as other_user
    show_page.visit!

    expect(page).to have_no_css("#meeting-agenda-items-new-button-component")
    expect(page).to have_test_selector("op-meeting-agenda-actions", count: 3)

    show_page.open_menu(second) do
      expect(page).to have_css(".ActionListItem-label", text: "Copy link to clipboard")
      expect(page).to have_css(".ActionListItem-label", count: 1)
    end
  end

  it "can delete a meeting and get back to the index page" do
    show_page.trigger_dropdown_menu_item "Delete meeting"
    show_page.expect_modal "Delete meeting"

    show_page.within_modal "Delete meeting" do
      click_on "Delete"
    end

    expect(page).to have_current_path project_meetings_path(project)

    expect_flash(type: :success, message: "Successful deletion.")
  end

  it "can open the export dialog" do
    show_page.trigger_dropdown_menu_item "Export PDF"
    show_page.expect_modal "Export PDF"

    show_page.within_modal "Export PDF" do
      expect(page).to have_button("Download")
    end
  end

  context "when exporting as ICS" do
    before do
      @download_list = DownloadList.new
    end

    after do
      DownloadList.clear
    end

    subject { @download_list.refresh_from(page).latest_download.to_s }

    it "can export the meeting as ICS" do
      click_on("op-meetings-header-action-trigger")

      click_on I18n.t(:label_icalendar_download)

      # dynamically wait for download to finish, otherwise expectation is too early
      seconds = 0
      while seconds < 5
        # don't use subject as it will not get reevaluated in the next iteration
        break if @download_list.refresh_from(page).latest_download.to_s != ""

        sleep 1
        seconds += 1
      end

      expect(subject).to end_with ".ics"
    end
  end

  it "shows an error toast trying to update an outdated item" do
    # Can add and edit a single item
    show_page.add_agenda_item do
      fill_in "Title", with: "My agenda item"
      fill_in "Duration", with: "25"
    end

    show_page.expect_agenda_item title: "My agenda item"
    item = MeetingAgendaItem.find_by!(title: "My agenda item")

    show_page.edit_agenda_item(item, save: false) do
      # Side effect: update the item
      item.update!(title: "Updated title")

      fill_in "Title", with: "My agenda item edited"
      click_on "Save" # triggers an error
    end

    expect(page).to have_css(".flash", text: I18n.t("activerecord.errors.messages.error_conflict"))
  end

  it "can duplicate the meeting via the dialog form" do
    show_page.add_agenda_item do
      fill_in "Title", with: "My agenda item"
      fill_in "Duration", with: "25"
    end

    show_page.expect_agenda_item title: "My agenda item"

    show_page.open_participant_form
    show_page.in_participant_form do
      show_page.select_participant(other_user)

      page.find(".close-button").click
    end

    wait_for_network_idle

    # check that no emails are sent out in draft mode
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.size).to eq 0

    retry_block do
      click_on("op-meetings-header-action-trigger")
      click_on "Duplicate"
      # dynamically wait for the modal to be loaded
      show_page.expect_modal("Duplicate meeting")
    end

    fill_in "Title", with: ""
    click_on "Create meeting"

    # check for dialog form validations
    expect(page).to have_content "Title can't be blank."
    fill_in "Title", with: "Some title"
    click_on "Create meeting"
    expect_and_dismiss_flash(type: :success, message: I18n.t(:notice_successful_create))

    new_meeting = Meeting.last
    copied_meeting_page = Pages::Meetings::Show.new(new_meeting)
    expect(page).to have_current_path "/projects/#{project.identifier}/meetings/#{new_meeting.id}"

    # check for copied agenda items
    copied_meeting_page.expect_agenda_item title: "My agenda item"

    new_meeting.update!(state: "in_progress")

    # check for copied participants with attended status reset
    copied_meeting_page.open_participant_form
    copied_meeting_page.in_participant_form do
      copied_meeting_page.expect_participant(user)
      copied_meeting_page.expect_participant(other_user)
    end

    # check that no emails are sent out as the copied meeting is in draft mode
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.size).to eq 0
  end

  context "with a work package reference to another" do
    let!(:meeting) { create(:meeting, project:, author: current_user) }
    let!(:other_project) { create(:project) }
    let!(:other_wp) { create(:work_package, project: other_project, author: current_user, subject: "Private task") }
    let!(:role) { create(:project_role, permissions: %w[view_work_packages]) }
    let!(:membership) { create(:member, principal: user, project: other_project, roles: [role]) }
    let!(:agenda_item) { create(:wp_meeting_agenda_item, meeting:, author: current_user, work_package: other_wp) }
    let(:show_page) { Pages::Meetings::Show.new(meeting) }

    it "shows correctly for author, but returns an unresolved reference for the second user" do
      show_page.visit!
      show_page.expect_agenda_link agenda_item
      expect(page).to have_text "Private task"

      login_as other_user

      show_page.visit!
      show_page.expect_undisclosed_agenda_link agenda_item
      expect(page).to have_no_text "Private task"
    end
  end

  context "with sections" do
    let!(:meeting) { create(:meeting, project:, author: current_user) }
    let(:show_page) { Pages::Meetings::Show.new(meeting) }

    context "when starting with empty sections" do
      it "can add, edit and delete sections" do
        # create the first section
        show_page.add_section do
          fill_in "Title", with: "First section"
          click_on "Save"
        end

        show_page.expect_section(title: "First section")

        first_section = MeetingSection.find_by!(title: "First section")

        meeting = first_section.meeting

        # edit the first section
        show_page.edit_section(first_section) do
          fill_in "Title", with: "Updated first section title"
          click_on "Save"
        end

        show_page.expect_no_section title: "First section"
        show_page.expect_section title: "Updated first section title"

        # add a second section
        show_page.add_section do
          fill_in "Title", with: "Second section"
          click_on "Save"
        end

        show_page.expect_section(title: "Updated first section title")
        show_page.expect_section(title: "Second section")

        second_section = MeetingSection.find_by!(title: "Second section")

        # remove the second section
        show_page.remove_section second_section

        ## the first section is still rendered explicitly, as a name was specified
        show_page.expect_section(title: "Updated first section title")
        show_page.expect_no_section(title: "Second section")

        # add a section without a name is not possible
        show_page.add_section do
          click_on "Save"
          expect(page).to have_text "Title can't be blank"
          click_on "Cancel"
        end

        # remove the first section
        show_page.remove_section first_section
        show_page.expect_no_section(title: "Updated first section title")

        # now the meeting is completely empty again
        show_page.expect_blankslate

        # add an item to the meeting
        show_page.add_agenda_item do
          fill_in "Title", with: "First item without explicit section"
        end

        # the agenda item is wrapped in an "untitled" section, but the section is not explicitly rendered
        show_page.expect_no_section(title: "Untitled section")

        # add a second section again
        show_page.add_section do
          fill_in "Title", with: "Second section"
          click_on "Save"
        end

        ## the first section without a name is now explicitly rendered as "Untitled"
        show_page.expect_section(title: "Untitled section")
        show_page.expect_section(title: "Second section")

        second_section = MeetingSection.find_by!(title: "Second section")

        # try to add an item to the latest section
        show_page.add_agenda_item(save: false) do
          fill_in "Title", with: "First item"
          fill_in "Duration", with: "25"
        end

        # a confirmation prevents losing unsaved edit state when reordering sections
        dismiss_confirm do
          show_page.select_section_action(second_section, "Move to top")
        end

        click_on "Cancel"

        # remove the second section
        show_page.remove_section second_section

        ## the last existing section is not explicitly rendered as a section as no name was specified for this section
        ## it goes back to "no section mode"
        show_page.expect_no_section(title: "Second section")
        show_page.expect_no_section(title: "Untitled section")

        # removing the last agenda item will automatically remove the hidden first section as well
        first_item = MeetingAgendaItem.find_by!(title: "First item without explicit section")
        show_page.remove_agenda_item(first_item)
        show_page.expect_blankslate

        # add a second section again
        show_page.add_section do
          fill_in "Title", with: "Second section"
          click_on "Save"
        end

        ## as there is no agenda item, the first section is not automatically created and thus
        ## there is only the explicitly created section
        show_page.expect_section(title: "Second section")

        second_section = MeetingSection.find_by!(title: "Second section")

        # add an item to the latest section
        show_page.add_agenda_item do
          fill_in "Title", with: "First item"
          fill_in "Duration", with: "25"
        end

        show_page.expect_agenda_item_in_section title: "First item", section: second_section

        # duration for the section is shown
        show_page.expect_section_duration(section: second_section, duration_text: "25 min")

        item_in_second_section = MeetingAgendaItem.find_by!(title: "First item")

        show_page.edit_agenda_item(item_in_second_section) do
          fill_in "Duration", with: "15"
        end

        # duration gets updated
        show_page.expect_section_duration(section: second_section, duration_text: "15 min")

        # deleting a section with agenda items is possible with a confirmation
        accept_confirm do
          show_page.select_section_action(second_section, "Delete")
        end

        expect { item_in_second_section.reload }.to raise_error(ActiveRecord::RecordNotFound)

        # no sections are left, and so the blankslate will be rendered
        show_page.expect_blankslate
      end
    end

    it "maintains section order when rendering" do
      section1 = create(:meeting_section, meeting:, title: "Section A")
      section2 = create(:meeting_section, meeting:, title: "Section B")
      section3 = create(:meeting_section, meeting:, title: "Section C")

      show_page.visit!

      expect(show_page.section_headers)
        .to eq(["Section A", "Section B", "Section C"])

      show_page.select_section_action(section3, "Move up")

      wait_for { [section1, section2, section3].map { |s| s.reload.position } }
        .to eq([1, 3, 2])
      wait_for { show_page.section_headers }
        .to eq(["Section A", "Section C", "Section B"])

      show_page.reload!

      expect(show_page.section_headers)
        .to eq(["Section A", "Section C", "Section B"])
    end
  end
end
