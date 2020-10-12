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
  let(:project) { FactoryBot.create :project, enabled_module_names: %w[meetings activity] }
  let(:user) { FactoryBot.create(:admin) }

  let!(:meeting) { FactoryBot.create :meeting, project: project, title: 'Awesome meeting!' }
  let!(:agenda) { FactoryBot.create :meeting_agenda, meeting: meeting, text: 'foo' }
  let!(:minutes) { FactoryBot.create :meeting_minutes, meeting: meeting, text: 'minutes' }

  before do
    login_as(user)
  end

  describe 'project activity' do
    it 'can show the meeting in the project activity' do
      visit project_activity_index_path(project)

      check 'Meetings'
      click_on 'Apply'

      expect(page).to have_selector('li.meeting', text: 'Awesome meeting!')
      expect(page).to have_selector('.meeting-agenda', text: 'Agenda: Awesome meeting!')
    end
  end
end
