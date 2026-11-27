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

RSpec.describe "Meetings links caught by turbo",
               :js do
  include Rails.application.routes.url_helpers
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user,
           lastname: "First",
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings manage_agendas
                                                    view_work_packages] }).tap do |u|
      u.pref[:time_zone] = "Etc/UTC"

      u.save!
    end
  end
  shared_let(:presenter_candidate) do
    create(:user,
           firstname: "Paula",
           lastname: "Presenter",
           member_with_permissions: { project => %i[view_meetings] })
  end
  shared_let(:meeting1) { create(:meeting, title: "First meeting", project:) }
  shared_let(:meeting2) { create(:meeting, title: "Other meeting", project:) }

  let(:notes) do
    <<~NOTES
      [Meeting link](#{meeting_url(meeting2)})
    NOTES
  end
  let!(:agenda_item) { create(:meeting_agenda_item, meeting: meeting1, notes:) }
  let!(:other_item) { create(:meeting_agenda_item, meeting: meeting1, title: "Plain item") }
  let(:show_page) { Pages::Meetings::Show.new(meeting1) }
  let(:unsaved_changes_message) do
    "You have unsaved changes on this page. Are you sure you want to discard them?"
  end

  before do
    login_as user
    show_page.visit!
  end

  it "can link to the other meeting" do
    click_link_or_button "Meeting link"
    expect(page).to have_current_path project_meeting_path(project, meeting2)
    expect(page).to have_css("#content", text: "Other meeting", visible: :visible)
  end

  it "warns before following a Turbo link with an unsaved agenda item title" do
    show_page.edit_agenda_item(other_item, save: false) do
      fill_in "Title", with: "Changed title"
    end

    dismiss_confirm(unsaved_changes_message) do
      within("#main-menu") { click_on "Meetings", match: :first }
    end
    expect(page).to have_current_path project_meeting_path(project, meeting1)
    show_page.expect_item_edit_title(other_item, "Changed title")

    accept_confirm(unsaved_changes_message) do
      within("#main-menu") { click_on "Meetings", match: :first }
    end
    expect(page).to have_current_path project_meetings_path(project), ignore_query: true
  end

  it "follows a Turbo link without warning when the opened form is unchanged" do
    show_page.edit_agenda_item(other_item, save: false) do
      expect(page).to have_field "Title", with: "Plain item"
    end

    within("#main-menu") { click_on "Meetings", match: :first }
    expect(page).to have_current_path project_meetings_path(project), ignore_query: true
  end

  it "warns before the g m shortcut leaves with an unsaved agenda item title" do
    show_page.edit_agenda_item(other_item, save: false) do
      fill_in "Title", with: "Changed title"
    end
    find_test_selector("op-meeting-agenda-title", text: agenda_item.title).click

    dismiss_confirm(unsaved_changes_message) do
      page.send_keys("g", "m")
    end
    expect(page).to have_current_path project_meeting_path(project, meeting1)
    show_page.expect_item_edit_title(other_item, "Changed title")
  end

  it "warns before following a Turbo link with only an unsaved presenter change" do
    show_page.edit_agenda_item(other_item, save: false) do
      select_autocomplete(find("opce-user-autocompleter"),
                          query: "Paula",
                          select_text: "Paula Presenter",
                          results_selector: "body")
    end

    dismiss_confirm(unsaved_changes_message) do
      within("#main-menu") { click_on "Meetings", match: :first }
    end
    expect(page).to have_current_path project_meeting_path(project, meeting1)
  end
end
