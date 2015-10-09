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

describe 'Projects', type: :feature do
  let(:current_user) { FactoryGirl.create(:admin) }
  let!(:project_type) { FactoryGirl.create(:project_type, name: 'Standard Foo')}

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe 'creation', js: true do
    it 'can create a project' do
      visit admin_path
      click_on 'New project'

      fill_in 'project[name]', with: 'Foo bar'
      click_on 'Advanced settings'
      fill_in 'project[identifier]', with: 'foo'
      select 'Standard Foo', from: 'project[project_type_id]'
      click_on 'Create'
      expect(page).to have_content 'Successful creation.'
    end
  end

  describe 'project types' do
    let(:phase_type)     { FactoryGirl.create(:type, name: 'Phase', is_default: true) }
    let(:milestone_type) { FactoryGirl.create(:type, name: 'Milestone', is_default: false) }
    let!(:project) { FactoryGirl.create(:project, name: 'Foo project', types: [phase_type, milestone_type]) }

    it "have the correct types checked for the project's types" do
      visit admin_path
      click_on 'Foo project'
      click_on 'Types'

      field_checked = find_field('Phase', visible: false)['checked']
      expect(field_checked).to be_truthy
      field_checked = find_field('Milestone', visible: false)['checked']
      expect(field_checked).to be_truthy
    end
  end
end
