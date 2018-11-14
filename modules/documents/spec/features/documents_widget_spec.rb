#-- copyright
# OpenProject Documents Plugin
#
# Former OpenProject Core functionality extracted into a plugin.
#
# Copyright (C) 2009-2014 the OpenProject Foundation (OPF)
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

require_relative '../spec_helper'

describe 'Documents widget', type: :feature, js: true do
  let(:project) { FactoryBot.create(:project) }
  let(:user) do
    FactoryBot.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end
  let(:role) { FactoryBot.create(:role, permissions: [:edit_project]) }

  before do
    allow(User)
      .to receive(:current)
      .and_return(user)
  end

  if Redmine::Plugin.registered_plugins[:openproject_my_project_page]
    it 'has a "Document" widget on the my project page' do
      visit my_projects_overview_path project

      select 'Documents', from: 'block-select'

      within '#list-hidden' do
        expect(page).to have_content('Documents')
      end

      expect(page.find('#block-select option', text: 'Documents')['disabled']).to eql 'true'
    end
  end

  it 'has a "Document" widget on the my page' do
    visit my_page_layout_path

    select 'Documents', from: 'block-options'
    click_button 'Add'

    expect(page).to have_selector('.widget-box--header-title', text: 'Documents', wait: 10)
    expect(page.find('#block-options option', text: 'Documents')['disabled']).to eql 'true'
  end
end
