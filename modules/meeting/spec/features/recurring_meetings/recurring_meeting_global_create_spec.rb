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
require_relative "../../support/pages/recurring_meeting/show"
require_relative "../../support/pages/meetings/index"

RSpec.describe "Recurring meetings global creation",
               :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user,
           lastname: "First",
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings] }).tap do |u|
      u.pref[:time_zone] = "Etc/UTC"

      u.save!
    end
  end

  let(:meetings_page) { Pages::Meetings::Index.new(project: nil) }

  context "with a user with permissions" do
    before do
      login_as(user)
      meetings_page.visit!
    end

    it "keeps the current selected project when hitting a validation error (Regression #59972)" do
      expect(page).to have_current_path(meetings_page.path)
      meetings_page.click_on "add-meeting-button"

      page.within("action-list") do
        meetings_page.click_on "Recurring"
      end

      meetings_page.set_project project
      meetings_page.click_create(wait_for: :turbo_stream)

      expect(page).to have_text "Title can't be blank."

      within("[data-test-selector='project_id']") do
        expect(page).to have_text project.name
      end

      meetings_page.set_title "Some title"
      meetings_page.click_create

      expect(page).to have_heading "Some title"
      meeting = Meeting.last
      expect(meeting.title).to eq "Some title"
      expect(meeting.project).to eq project
    end

    it "shows a project validation error when empty (Regression #61176)" do
      expect(page).to have_current_path(meetings_page.path)
      meetings_page.click_on "add-meeting-button"

      page.within("action-list") do
        meetings_page.click_on "Recurring"
      end

      meetings_page.set_title "Some title"
      meetings_page.click_create(wait_for: :turbo_stream)

      expect(page).to have_text "Project can't be blank."
      meetings_page.set_project project

      within("[data-test-selector='project_id']") do
        expect(page).to have_text project.name
      end
      meetings_page.click_create

      expect(page).to have_heading "Some title (Template)"
      meeting = Meeting.last
      expect(meeting.title).to eq "Some title"
      expect(meeting.project).to eq project
    end
  end
end
