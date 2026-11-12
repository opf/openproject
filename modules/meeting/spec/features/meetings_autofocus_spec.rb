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

require_relative "../support/pages/meetings/show"

RSpec.describe "Meetings autofocus", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings work_package_tracking]) }
  shared_let(:user) do
    create :user,
           lastname: "First",
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings manage_agendas
                                                    manage_outcomes view_work_packages] }
  end
  shared_let(:meeting) do
    create :meeting,
           project:,
           author: user,
           state: :in_progress
  end
  shared_let(:work_package) do
    create(:work_package, project:, subject: "Important task")
  end

  let(:current_user) { user }
  let(:show_page) { Pages::Meetings::Show.new(meeting) }

  let(:notes_field) do
    TextEditorField.new(page, "Notes", selector: ".op-meeting-agenda-item-form--notes")
  end

  def outcome_field_for(agenda_item)
    TextEditorField.new(page, "Outcome", selector: test_selector("meeting-outcome-input-for-#{agenda_item.id}"))
  end

  before do
    login_as current_user
    show_page.visit!
  end

  it do
    ## without sections
    # add item
    show_page.add_agenda_item do
      show_page.expect_focused_input("form_new_meeting_agenda_item_title")

      fill_in "Title", with: "My agenda item"
    end

    # add notes to item
    show_page.expect_agenda_item title: "My agenda item"
    item = MeetingAgendaItem.find_by(title: "My agenda item")

    show_page.select_action(item, I18n.t(:label_agenda_item_add_notes))

    show_page.expect_focused_ckeditor

    notes_field.expect_active!
    notes_field.set_value "Some notes"
    click_on "Save"
    show_page.expect_notes("Some notes")

    # edit item
    show_page.edit_agenda_item(item) do
      show_page.expect_focused_input("form_#{item.id}_meeting_agenda_item_title")

      fill_in "Title", with: "Updated title"
    end
    show_page.expect_agenda_item title: "Updated title"

    # add second item
    show_page.add_agenda_item do
      show_page.expect_focused_input("form_new_meeting_agenda_item_title")

      fill_in "Title", with: "Second"
    end

    show_page.expect_agenda_item title: "Second"
    second = MeetingAgendaItem.find_by(title: "Second")
    outcome_field = outcome_field_for(second)

    # add outcome
    show_page.add_outcome_from_menu(second) do
      show_page.expect_focused_ckeditor

      outcome_field.expect_active!
      outcome_field.set_value "An outcome for second"
      click_on "Save"
    end
    show_page.expect_outcome "An outcome for second"

    # edit outcome
    show_page.in_outcome_component(second) do
      show_page.select_outcome_action(I18n.t(:label_agenda_outcome_edit))

      show_page.expect_focused_ckeditor

      outcome_field.expect_active!
      outcome_field.set_value "Updated outcome"
      click_link_or_button "Save"

      show_page.expect_outcome "Updated outcome"
    end

    # add wp item
    show_page.add_agenda_item(type: WorkPackage) do
      show_page.expect_focused_input("form_new_meeting_agenda_item_work_package_id")

      select_autocomplete(find_test_selector("op-agenda-items-wp-autocomplete"),
                          query: "task",
                          results_selector: "body")
    end

    show_page.expect_agenda_link work_package
    wp_item = MeetingAgendaItem.find_by(work_package_id: work_package.id)
    expect(wp_item).to be_present

    # edit wp item
    show_page.edit_agenda_item(wp_item, save: false) do
      show_page.expect_focused_input("form_#{wp_item.id}_meeting_agenda_item_work_package_id")
      click_on "Cancel"
    end

    # add notes to wp item
    show_page.select_action(wp_item, I18n.t(:label_agenda_item_add_notes))

    show_page.expect_focused_ckeditor
    click_on "Cancel"

    MeetingAgendaItem.last(3).each(&:destroy)
    show_page.visit!

    ## for sections
    # add section
    show_page.add_section do
      show_page.expect_focused_input("meeting_section_title")

      fill_in "Title", with: "First section"
      click_on "Save"
    end

    show_page.expect_section(title: "First section")
    first_section = MeetingSection.find_by!(title: "First section")

    # edit section
    show_page.edit_section(first_section) do
      show_page.expect_focused_input("meeting_section_title")

      fill_in "Title", with: "Updated first section"
      click_on "Save"
    end

    show_page.expect_section(title: "Updated first section")

    ## inside a section
    # add item
    show_page.add_agenda_item do
      show_page.expect_focused_input("form_new_meeting_agenda_item_title")

      fill_in "Title", with: "My agenda item"
    end

    # add notes to item
    show_page.expect_agenda_item title: "My agenda item"
    item = MeetingAgendaItem.find_by(title: "My agenda item")

    show_page.select_action(item, I18n.t(:label_agenda_item_add_notes))

    show_page.expect_focused_ckeditor

    notes_field.expect_active!
    notes_field.set_value "Some notes"
    click_on "Save"
    show_page.expect_notes("Some notes")

    # edit item
    show_page.edit_agenda_item(item) do
      show_page.expect_focused_input("form_#{item.id}_meeting_agenda_item_title")

      fill_in "Title", with: "Updated title"
    end
    show_page.expect_agenda_item title: "Updated title"

    # add second item
    show_page.add_agenda_item do
      show_page.expect_focused_input("form_new_meeting_agenda_item_title")

      fill_in "Title", with: "Second"
    end

    show_page.expect_agenda_item title: "Second"
    second = MeetingAgendaItem.find_by(title: "Second")
    outcome_field = outcome_field_for(second)

    # add outcome
    show_page.add_outcome_from_menu(second) do
      show_page.expect_focused_ckeditor

      outcome_field.expect_active!
      outcome_field.set_value "An outcome for second"
      click_on "Save"
    end
    show_page.expect_outcome "An outcome for second"

    # edit outcome
    show_page.in_outcome_component(second) do
      show_page.select_outcome_action(I18n.t(:label_agenda_outcome_edit))

      show_page.expect_focused_ckeditor

      outcome_field.expect_active!
      outcome_field.set_value "Updated outcome"
      click_link_or_button "Save"

      show_page.expect_outcome "Updated outcome"
    end

    # add wp item
    show_page.add_agenda_item(type: WorkPackage) do
      show_page.expect_focused_input("form_new_meeting_agenda_item_work_package_id")

      select_autocomplete(find_test_selector("op-agenda-items-wp-autocomplete"),
                          query: "task",
                          results_selector: "body")
    end

    show_page.expect_agenda_link work_package
    wp_item = MeetingAgendaItem.find_by(work_package_id: work_package.id)
    expect(wp_item).to be_present

    # edit wp item
    show_page.edit_agenda_item(wp_item, save: false) do
      show_page.expect_focused_input("form_#{wp_item.id}_meeting_agenda_item_work_package_id")
      click_on "Cancel"
    end

    # add notes to wp item
    show_page.select_action(wp_item, I18n.t(:label_agenda_item_add_notes))

    show_page.expect_focused_ckeditor
    click_on "Cancel"

    MeetingAgendaItem.last(3).each(&:destroy)
    show_page.visit!

    ## inside the backlog
    show_page.click_on_backlog
    show_page.expect_backlog collapsed: false

    # add item
    show_page.add_agenda_item_to_backlog do
      show_page.expect_focused_input("form_new_meeting_agenda_item_title")

      fill_in "Title", with: "My agenda item"
    end

    # add notes to item
    show_page.expect_agenda_item title: "My agenda item"
    item = MeetingAgendaItem.find_by(title: "My agenda item")

    show_page.select_action(item, I18n.t(:label_agenda_item_add_notes))

    show_page.expect_focused_ckeditor

    notes_field.expect_active!
    notes_field.set_value "Some notes"
    click_on "Save"
    show_page.expect_notes("Some notes")

    # edit item
    show_page.edit_agenda_item(item) do
      show_page.expect_focused_input("form_#{item.id}_meeting_agenda_item_title")

      fill_in "Title", with: "Updated title"
    end
    show_page.expect_agenda_item title: "Updated title"

    # add second item
    show_page.add_agenda_item_to_backlog do
      show_page.expect_focused_input("form_new_meeting_agenda_item_title")

      fill_in "Title", with: "Second"
    end

    show_page.expect_agenda_item title: "Second"

    # add wp item
    show_page.add_agenda_item_to_backlog(type: WorkPackage) do
      show_page.expect_focused_input("form_new_meeting_agenda_item_work_package_id")

      select_autocomplete(find_test_selector("op-agenda-items-wp-autocomplete"),
                          query: "task",
                          results_selector: "body")
    end

    show_page.expect_agenda_link work_package
    wp_item = MeetingAgendaItem.find_by(work_package_id: work_package.id)
    expect(wp_item).to be_present

    # edit wp item
    show_page.edit_agenda_item(wp_item, save: false) do
      show_page.expect_focused_input("form_#{wp_item.id}_meeting_agenda_item_work_package_id")
      click_on "Cancel"
    end

    # add notes to wp item
    show_page.select_action(wp_item, I18n.t(:label_agenda_item_add_notes))

    show_page.expect_focused_ckeditor
  end
end
