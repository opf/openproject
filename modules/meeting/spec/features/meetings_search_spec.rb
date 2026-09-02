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

RSpec.describe "Meeting search", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:project) { create(:project) }
  let(:role) { create(:project_role, permissions: %i(view_meetings view_work_packages)) }
  let(:user) { create(:user, member_with_roles: { project => role }) }

  let!(:meeting) { create(:meeting, project:) }
  let!(:agenda_item) { create(:meeting_agenda_item, meeting:) }
  let(:global_search) { Components::GlobalSearch.new }

  before do
    login_as user

    visit project_path(project)
  end

  context "global search" do
    it "works with a title" do
      global_search.search("Meeting")
      global_search.submit_in_current_project

      global_search.open_tab :meetings
      expect(page.find_by_id("search-results")).to have_text(meeting.title)
    end

    it "works with an agenda item title" do
      global_search.search(agenda_item.title)
      global_search.submit_in_current_project

      global_search.open_tab :meetings
      expect(page.find_by_id("search-results")).to have_text(meeting.title)
    end

    it "works with an agenda item notes" do
      global_search.search(agenda_item.notes)
      global_search.submit_in_current_project

      global_search.open_tab :meetings
      expect(page.find_by_id("search-results")).to have_text(meeting.title)
    end
  end

  context "when searching from a different project context" do
    let(:parent_project) { create(:project) }
    let(:child_project) { create(:project, parent: parent_project) }
    let(:role) { create(:project_role, permissions: %i(view_meetings view_work_packages)) }
    let(:user) do
      create(:user, member_with_roles: { parent_project => role, child_project => role })
    end

    let!(:meeting) { create(:meeting, project: child_project) }
    let!(:agenda_item) { create(:meeting_agenda_item, meeting:) }

    before do
      visit project_path(parent_project)
    end

    it "opens the meeting in its own project" do
      global_search.search(agenda_item.notes)
      global_search.submit_in_project_and_subproject_scope

      global_search.open_tab :meetings
      page.find_by_id("search-results").click_link(meeting.title)

      expect(page).to have_current_path(project_meeting_path(child_project, meeting))
      expect(page).to have_text(meeting.title)
    end
  end
end
