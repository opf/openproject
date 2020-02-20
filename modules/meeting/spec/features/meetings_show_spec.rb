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

describe 'Meetings', type: :feature, js: true do
  let(:project) { FactoryBot.create :project, enabled_module_names: %w[meetings] }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end

  let!(:meeting) { FactoryBot.create :meeting, project: project, title: 'Awesome meeting!' }

  before do
    login_as(user)
  end

  describe 'navigate to meeting page' do
    let(:permissions) { %i[view_meetings] }

    it 'can visit the meeting' do
      visit meetings_path(project)

      find('.meeting a', text: 'Awesome meeting!', wait: 10).click
      expect(page).to have_selector('h2', text: 'Meeting: Awesome meeting!')

      expect(page).to have_selector('.meeting_agenda', text: 'There is currently nothing to display')
    end

    context 'with an open agenda' do
      let!(:agenda) { FactoryBot.create :meeting_agenda, meeting: meeting, text: 'foo' }
      let(:agenda_update) { FactoryBot.create :meeting_agenda, meeting: meeting, text: 'bla' }

      it 'shows the agenda' do
        visit meeting_path(meeting)
        expect(page).to have_selector('#meeting_agenda-text', text: 'foo')

        # May not edit
        expect(page).to have_no_selector('#edit-meeting_agenda')
        expect(page).to have_no_selector('.meeting_agenda', text: 'Edit')
      end

      it 'can view history' do
        agenda_update

        visit meeting_path(meeting)
        click_on 'History'

        find('#version-1').click
        expect(page).to have_selector('.meeting_agenda', text: 'foo')
      end

      context 'and edit permissions' do
        let(:permissions) { %i[view_meetings create_meeting_agendas] }

        it 'can edit the agenda' do
          visit meeting_path(meeting)

          find('.toolbar-item', text: 'Edit').click

          expect(page).to have_selector('.meeting_agenda', text: 'Edit')
          expect(page).to have_selector('#edit-meeting_agenda')
        end
      end

      context 'and edit minutes permissions' do
        let(:permissions) { %i[view_meetings create_meeting_minutes] }

        it 'can not edit the minutes' do
          visit meeting_path(meeting)
          click_link 'Minutes'
          expect(page).to have_no_selector('.meeting_minutes', text: 'Edit')
          expect(page).to have_selector('.meeting_minutes', text: 'There is currently nothing to display')
        end
      end
    end

    context 'with a locked agenda' do
      let!(:agenda) { FactoryBot.create :meeting_agenda, meeting: meeting, text: 'foo', locked: true }

      it 'shows the minutes when visiting' do
        visit meeting_path(meeting)
        expect(page).to have_no_selector('h2', text: 'Agenda')
        expect(page).to have_no_selector('#edit-meeting_minutes')
        expect(page).to have_selector('h2', text: 'Minutes')
      end

      context 'and edit permissions' do
        let(:permissions) { %i[view_meetings create_meeting_minutes] }

        it 'can edit the minutes' do
          visit meeting_path(meeting)
          expect(page).to have_selector('#edit-meeting_minutes')
          expect(page).to have_selector('.meeting_minutes', text: 'Edit')
          expect(page).to have_no_selector('.button', text: 'Close the meeting to begin the Minutes')
        end
      end
    end
  end
end
