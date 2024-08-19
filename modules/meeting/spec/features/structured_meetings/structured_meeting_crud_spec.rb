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

require_relative "../../support/pages/meetings/new"
require_relative "../../support/pages/structured_meeting/show"

RSpec.describe "Structured meetings CRUD",
               :js,
               :with_cuprite do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           lastname: "First",
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings manage_agendas
                                                    view_work_packages] }).tap do |u|
      u.pref[:time_zone] = "utc"

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
  let(:new_page) { Pages::Meetings::New.new(project) }
  let(:meeting) { StructuredMeeting.order(id: :asc).last }
  let(:show_page) { Pages::StructuredMeeting::Show.new(meeting) }

  before do |test|
    login_as current_user
    new_page.visit!
    expect(page).to have_current_path(new_page.path) # rubocop:disable RSpec/ExpectInHook
    new_page.set_title "Some title"
    new_page.set_type "Dynamic"

    new_page.set_start_date "2013-03-28"
    new_page.set_start_time "13:30"
    new_page.set_duration "1.5"
    new_page.invite(other_user)

    if test.metadata[:checked]
      expect(page).to have_unchecked_field "send_notifications" # rubocop:disable RSpec/ExpectInHook
      check "send_notifications"
    end

    new_page.click_create
  end

  it "can create a structured meeting and add agenda items" do
    show_page.expect_toast(message: "Successful creation")

    # Does not send invitation mails by default
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.size).to eq 0

    # Can add and edit a single item
    show_page.add_agenda_item do
      fill_in "Title", with: "My agenda item"
      fill_in "min", with: "25"
    end

    show_page.expect_agenda_item title: "My agenda item"
    item = MeetingAgendaItem.find_by(title: "My agenda item")

    # Can update
    show_page.edit_agenda_item(item) do
      fill_in "Title", with: "Updated title"
      click_on "Save"
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
    show_page.select_action(second, I18n.t(:label_sort_higher))
    show_page.assert_agenda_order! "Updated title", "Second", "First"

    first = MeetingAgendaItem.find_by!(title: "First")
    show_page.select_action(first, I18n.t(:label_sort_highest))
    show_page.assert_agenda_order! "First", "Updated title", "Second"

    # Can edit and cancel with escape
    show_page.edit_agenda_item(first) do
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
    show_page.edit_agenda_item(wp_item) do
      show_page.clear_item_edit_work_package_title
      click_on "Save"
    end

    show_page.expect_item_edit_field_error(wp_item, "Work package can't be blank.")
    show_page.cancel_edit_form(wp_item)

    # Keeping the editing state of an agenda item while modifying other items
    show_page.edit_agenda_item(second) do
      fill_in "Title", with: "Second edited"
    end

    show_page.select_action(item, I18n.t(:label_sort_lowest))

    show_page.add_agenda_item do
      fill_in "Title", with: "My agenda item"
      fill_in "min", with: "25"
    end

    show_page.expect_agenda_item title: "My agenda item"
    my_item = MeetingAgendaItem.find_by!(title: "My agenda item")

    show_page.edit_agenda_item(my_item) do
      fill_in "Title", with: "My agenda item edited"
      click_on "Save"
    end

    show_page.remove_agenda_item my_item

    show_page.expect_item_edit_form(second)
    show_page.expect_item_edit_title(second, "Second edited")
    show_page.cancel_edit_form(second)

    # user can see actions
    expect(page).to have_css("#meeting-agenda-items-new-button-component")
    expect(page).to have_test_selector("op-meeting-agenda-actions", count: 3)

    # other_use can view, but not edit
    login_as other_user
    show_page.visit!

    expect(page).to have_no_css("#meeting-agenda-items-new-button-component")
    expect(page).not_to have_test_selector("op-meeting-agenda-actions")
  end

  it "can delete a meeting and get back to the index page" do
    click_on("op-meetings-header-action-trigger")

    accept_confirm(I18n.t("text_are_you_sure")) do
      click_on "Delete meeting"
    end

    expect(page).to have_current_path project_meetings_path(project)
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
    show_page.expect_toast(message: "Successful creation")

    # Can add and edit a single item
    show_page.add_agenda_item do
      fill_in "Title", with: "My agenda item"
      fill_in "min", with: "25"
    end

    show_page.expect_agenda_item title: "My agenda item"
    item = MeetingAgendaItem.find_by!(title: "My agenda item")

    show_page.edit_agenda_item(item) do
      # Side effect: update the item
      item.update!(title: "Updated title")

      fill_in "Title", with: "My agenda item edited"
      click_on "Save"
    end

    expect(page).to have_css(".flash", text: I18n.t("activerecord.errors.messages.error_conflict"))
  end

  it "can copy the meeting" do
    show_page.expect_toast(message: "Successful creation")

    # Can add and edit a single item
    show_page.add_agenda_item do
      fill_in "Title", with: "My agenda item"
      fill_in "min", with: "25"
    end

    show_page.expect_agenda_item title: "My agenda item"
    item = MeetingAgendaItem.find_by!(title: "My agenda item")

    click_on("op-meetings-header-action-trigger")
    click_on "Copy"

    expect(page).to have_current_path "/meetings/#{meeting.id}/copy"

    click_on "Create"

    show_page.expect_agenda_item title: "My agenda item"
    new_meeting = StructuredMeeting.reorder(id: :asc).last
    expect(page).to have_current_path "/projects/#{project.identifier}/meetings/#{new_meeting.id}"
  end

  context "with a work package reference to another" do
    let!(:meeting) { create(:structured_meeting, project:, author: current_user) }
    let!(:other_project) { create(:project) }
    let!(:other_wp) { create(:work_package, project: other_project, author: current_user, subject: "Private task") }
    let!(:role) { create(:project_role, permissions: %w[view_work_packages]) }
    let!(:membership) { create(:member, principal: user, project: other_project, roles: [role]) }
    let!(:agenda_item) { create(:wp_meeting_agenda_item, meeting:, author: current_user, work_package: other_wp) }
    let(:show_page) { Pages::StructuredMeeting::Show.new(meeting) }

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

  it "sends emails on creation when 'Send emails' is checked", :checked do
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.size).to eq 2
  end

  context "with sections" do
    let!(:meeting) { create(:structured_meeting, project:, author: current_user) }
    let(:show_page) { Pages::StructuredMeeting::Show.new(meeting) }

    context "when starting with empty sections" do
      it "can add, edit and delete sections" do
        show_page.expect_toast(message: "Successful creation")

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
        end

        # remove the first section
        show_page.remove_section first_section
        show_page.expect_no_section(title: "Updated first section title")

        # now the meeting completely empty again

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

        # remove the second section
        show_page.remove_section second_section

        ## the last existing section is not explicitly rendered as a section as no name was specified for this section
        ## -> back to "no section mode"
        show_page.expect_no_section(title: "Second section")
        show_page.expect_no_section(title: "Untitled section")

        # TBD: remove the agenda item again, the untitle section is not rendered explicitly and will not be removed
        first_item = MeetingAgendaItem.find_by!(title: "First item without explicit section")
        show_page.remove_agenda_item(first_item)

        # add a second section again
        show_page.add_section do
          fill_in "Title", with: "Second section"
          click_on "Save"
        end

        ## the first section without a name is now again explicitly rendered as "Untitled"
        show_page.expect_section(title: "Untitled section")
        show_page.expect_section(title: "Second section")

        second_section = MeetingSection.find_by!(title: "Second section")

        # add an item to the latest section
        show_page.add_agenda_item do
          fill_in "Title", with: "First item"
          fill_in "min", with: "25"
        end

        show_page.expect_agenda_item_in_section title: "First item", section: second_section

        first_section = meeting.sections.first

        # add an item to the first section explicitly
        show_page.add_agenda_item_to_section(section: first_section) do
          fill_in "Title", with: "Second item"
          fill_in "min", with: "30"
        end

        show_page.expect_agenda_item_in_section title: "Second item", section: first_section

        # duration per section is shown
        show_page.expect_section_duration(section: first_section, duration_text: "30 min")
        show_page.expect_section_duration(section: second_section, duration_text: "25 min")

        item_in_first_section = MeetingAgendaItem.find_by!(title: "Second item")
        item_in_second_section = MeetingAgendaItem.find_by!(title: "First item")

        show_page.edit_agenda_item(item_in_second_section) do
          fill_in "min", with: "15"
          click_on "Save"
        end

        # duration gets updated
        show_page.expect_section_duration(section: second_section, duration_text: "15 min")

        # deleting a section with agenda items is not possible
        accept_confirm do
          show_page.select_section_action(second_section, "Delete")
        end

        # only untitled secion is left -> will not be rendered explicitly as secion
        show_page.expect_no_section(title: "Untitled section")
        show_page.expect_no_section(title: "Second section")

        expect { item_in_second_section.reload }.to raise_error(ActiveRecord::RecordNotFound)

        # the agenda items of the "untitled" section are still visible in "no-section mode"
        show_page.expect_agenda_item(title: item_in_first_section.title)
      end
    end
  end
end
