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

describe 'Meeting search', type: :feature, js: true do
  include ::Components::NgSelectAutocompleteHelpers
  let(:project) { FactoryBot.create :project }
  let(:user) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }
  let(:role) { FactoryBot.create :role, permissions: %i(view_meetings view_work_packages) }

  let!(:meeting) { FactoryBot.create(:meeting, project: project) }

  before do
    login_as user

    visit project_path(project)
  end

  context 'global search' do
    it 'works' do
      select_autocomplete(page.find('.top-menu-search--input'),
                          query: "Meeting",
                          select_text: "In this project ↵")

      page.find('[tab-id="meetings"]').click
      expect(page.find('#search-results')).to have_text(meeting.title)
    end
  end
end
