#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'My project page overview', type: :feature do
  let(:project) { FactoryBot.create :project }
  let(:overview) { FactoryBot.create :my_projects_overview, project: project }

  let(:button_selector) { '#my-project-page-layout' }

  before do
    overview
    login_as(user)

    visit project_path(project)
    expect(page).to have_selector('h2', text: 'Overview')
  end

  context 'as admin' do
    let(:user) { FactoryBot.create :admin }

    it 'shows the default blocks and edit button' do
      expect(page).to have_selector('.widget-box', count: 5)
      expect(page).to have_selector(button_selector)
    end
  end

  context 'as regular user' do
    let(:permissions) { %i(view_project) }
    let(:role) { FactoryBot.create :role, permissions: permissions }
    let(:user) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }

    it 'shows the default blocks, but no editing' do
      expect(page).to have_selector('.widget-box', count: 5)
      expect(page).to have_no_selector(button_selector)
    end
  end
end
