#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Meetings close', type: :feature do
  let(:project) { FactoryBot.create :project, enabled_module_names: %w[meetings] }
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: permissions)
  end
  let(:other_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: permissions)
  end

  let!(:meeting) { FactoryBot.create :meeting, project: project, title: 'Own awesome meeting!', author: user }
  let!(:meeting_agenda) { FactoryBot.create :meeting_agenda, meeting: meeting, text: "asdf" }

  before do
    login_as(user)
  end

  context 'with permission to close meetings', js: true do
    let(:permissions) { %i[view_meetings close_meeting_agendas] }

    it 'can delete own and other`s meetings' do
      visit meetings_path(project)

      click_link meeting.title

      # Go to minutes, expect uneditable
      find('.tabrow a', text: 'MINUTES').click

      expect(page).to have_selector('.button', text: 'Close the agenda to begin the Minutes')

      # Close the meeting
      find('.tabrow a', text: 'AGENDA').click
      find('.button', text: 'Close').click
      page.accept_confirm

      # Expect to be on minutes
      expect(page).to have_selector('.tabrow li.selected', text: 'MINUTES')

      # Copies the text
      expect(page).to have_selector('#meeting_minutes-text', text: 'asdf')

      # Go back to agenda, expect we can open it again
      find('.tabrow a', text: 'AGENDA').click
      find('.button', text: 'Open').click
      page.accept_confirm
      expect(page).to have_selector('.button', text: 'Close')
    end
  end

  context 'without permission to close meetings' do
    let(:permissions) { %i[view_meetings] }

    it 'cannot delete own and other`s meetings' do
      visit meetings_path(project)

      expect(page)
        .to have_no_link 'Close'
    end
  end
end
