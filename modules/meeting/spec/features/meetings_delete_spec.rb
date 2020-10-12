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

describe 'Meetings deletion', type: :feature do
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
  let!(:other_meeting) { FactoryBot.create :meeting, project: project, title: 'Other awesome meeting!', author: other_user }

  before do
    login_as(user)
  end

  context 'with permission to delete meetings', js: true do
    let(:permissions) { %i[view_meetings delete_meetings] }

    it 'can delete own and other`s meetings' do
      visit meetings_path(project)

      click_link meeting.title
      click_link "Delete"

      page.accept_confirm

      expect(page)
        .to have_current_path meetings_path(project)

      click_link other_meeting.title
      click_link "Delete"

      page.accept_confirm

      expect(page)
        .to have_content(I18n.t('.no_results_title_text', cascade: true))

      expect(current_path)
        .to eql meetings_path(project)
    end
  end

  context 'without permission to delete meetings' do
    let(:permissions) { %i[view_meetings] }

    it 'cannot delete own and other`s meetings' do
      visit meetings_path(project)

      click_link meeting.title
      expect(page)
        .to have_no_link 'Delete'

      visit meetings_path(project)

      click_link other_meeting.title
      expect(page)
        .to have_no_link 'Delete'
    end
  end
end
