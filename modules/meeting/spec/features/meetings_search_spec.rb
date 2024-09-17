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

  let!(:meeting) { create(:structured_meeting, project:) }
  let!(:agenda_item) { create(:meeting_agenda_item, meeting:) }

  before do
    login_as user

    visit project_path(project)
  end

  context "global search" do
    it "works with a title" do
      select_autocomplete(page.find(".top-menu-search--input"),
                          query: "Meeting",
                          select_text: "In this project ↵",
                          wait_dropdown_open: false)

      page.find('[data-qa-tab-id="meetings"]').click
      expect(page.find_by_id("search-results")).to have_text(meeting.title)
    end

    it "works with an agenda item title" do
      select_autocomplete(page.find(".top-menu-search--input"),
                          query: agenda_item.title,
                          select_text: "In this project ↵",
                          wait_dropdown_open: false)

      page.find('[data-qa-tab-id="meetings"]').click
      expect(page.find_by_id("search-results")).to have_text(meeting.title)
    end

    it "works with an agenda item notes" do
      select_autocomplete(page.find(".top-menu-search--input"),
                          query: agenda_item.notes,
                          select_text: "In this project ↵",
                          wait_dropdown_open: false)

      page.find('[data-qa-tab-id="meetings"]').click
      expect(page.find_by_id("search-results")).to have_text(meeting.title)
    end
  end
end
