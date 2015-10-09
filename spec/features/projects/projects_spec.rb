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
require 'features/projects/projects_page'

describe 'Projects', type: :feature do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe 'creation', js: true do
    let!(:project) { FactoryGirl.create(:project, name: 'Foo project', identifier: 'foo-project') }

    before do
      visit admin_path
    end

    it 'can create a project' do
      click_on 'New project'

      fill_in 'project[name]', with: 'Foo bar'
      click_on 'Advanced settings'
      fill_in 'project[identifier]', with: 'foo'
      click_on 'Create'

      expect(page).to have_content 'Successful creation.'
      expect(page).to have_content 'Foo bar'
      expect(current_path).to eq '/projects/foo/settings'
    end

    it 'can create a subproject' do
      click_on 'Foo project'
      click_on 'New subproject'

      fill_in 'project[name]', with: 'Foo child'
      click_on 'Create'

      expect(page).to have_content 'Successful creation.'
      expect(current_path).to eq '/projects/foo-child/settings'
    end

    it 'does not create a project with an already existing identifier' do
      click_on 'New project'

      fill_in 'project[name]', with: 'Foo project'
      click_on 'Create'

      expect(page).to have_content 'Identifier has already been taken'
      expect(current_path).to eq '/projects'
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

  describe 'deletion', js: true do
    let(:project) { FactoryGirl.create(:project) }
    let(:projects_page) { ProjectsPage.new(project) }

    before do
      projects_page.visit_confirm_destroy
    end

    describe 'disable delete w/o confirm' do
      it { expect(page).to have_css('.danger-zone .button[disabled]') }
    end

    describe 'disable delete with wrong input' do
      let(:input) { find('.danger-zone input') }
      it do
        input.set 'Not the project name'
        expect(page).to have_css('.danger-zone .button[disabled]')
      end
    end

    describe 'enable delete with correct input' do
      let(:input) { find('.danger-zone input') }
      it do
        input.set project.name
        expect(page).to have_css('.danger-zone .button:not([disabled])')
      end
    end
  end
end
