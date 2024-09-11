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

RSpec.describe "Meetings close" do
  let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end
  let(:other_user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end

  let!(:meeting) { create(:meeting, project:, title: "Own awesome meeting!", author: user) }
  let!(:meeting_agenda) { create(:meeting_agenda, meeting:, text: "asdf") }

  before do
    login_as(user)
  end

  context "with permission to close meetings", :js do
    let(:permissions) { %i[view_meetings close_meeting_agendas] }

    it "can delete own and other`s meetings" do
      visit meetings_path(project)

      click_on meeting.title

      # Go to minutes, expect uneditable
      find(".op-tab-row--link", text: "MINUTES").click

      expect(page).to have_css(".button", text: "Close the agenda to begin the Minutes")

      # Close the meeting
      find(".op-tab-row--link", text: "AGENDA").click
      accept_confirm do
        find(".button", text: "Close").click
      end

      # Expect to be on minutes
      expect(page).to have_css(".op-tab-row--link_selected", text: "MINUTES")

      # Copies the text
      expect(page).to have_css("#tab-content-minutes", text: "asdf")

      # Go back to agenda, expect we can open it again
      find(".op-tab-row--link", text: "AGENDA").click
      accept_confirm do
        find(".button", text: "Open").click
      end
      expect(page).to have_css(".button", text: "Close")
    end
  end

  context "without permission to close meetings" do
    let(:permissions) { %i[view_meetings] }

    it "cannot delete own and other`s meetings" do
      visit meetings_path(project)

      expect(page)
        .to have_no_link "Close"
    end
  end
end
