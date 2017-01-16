#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

feature 'group memberships through groups page', type: :feature, js: true do
  let!(:project) { FactoryGirl.create :project, name: 'Project 1', identifier: 'project1' }

  let(:admin)     { FactoryGirl.create :admin }
  let!(:peter)    { FactoryGirl.create :user, firstname: 'Peter', lastname: 'Pan' }
  let!(:hannibal) { FactoryGirl.create :user, firstname: 'Hannibal', lastname: 'Smith' }
  let!(:crash)    { FactoryGirl.create :user, firstname: "<script>alert('h4x');</script>",
                                              lastname: "<script>alert('h4x');</script>" }

  let(:group) { FactoryGirl.create :group, lastname: 'A-Team' }

  let!(:manager)   { FactoryGirl.create :role, name: 'Manager' }
  let!(:developer) { FactoryGirl.create :role, name: 'Developer' }

  let(:members_page) { Pages::Members.new project.identifier }

  before do
    allow(User).to receive(:current).and_return admin

    group.add_member! peter
    group.add_member! hannibal
  end

  shared_examples 'adding and removing principals' do
    scenario 'Adding and Removing a Group as Member' do
      members_page.visit!
      members_page.add_user! 'A-Team', as: 'Manager'

      expect(members_page).to have_added_group('A-Team')

      members_page.remove_group! 'A-Team'
      expect(page).to have_text 'Removed A-Team from project'
      expect(page).to have_text 'There are currently no members part of this project.'
    end

    scenario 'Adding and removing a User as Member' do
      members_page.visit!
      members_page.add_user! 'Hannibal Smith', as: 'Manager'

      expect(members_page).to have_added_user 'Hannibal Smith'

      members_page.remove_user! 'Hannibal Smith'
      expect(page).to have_text 'Removed Hannibal Smith from project'
      expect(page).to have_text 'There are currently no members part of this project.'
    end

    scenario 'Entering a Username as Member in firstname, lastname order' do
      members_page.visit!
      members_page.open_new_member!

      members_page.enter_principal_search! 'Hannibal S'
      expect(page).to have_text 'Hannibal Smith'
    end

    scenario 'Entering a Username as Member in lastname, firstname order' do
      members_page.visit!
      members_page.open_new_member!

      members_page.enter_principal_search! 'Smith, H'
      expect(page).to have_text 'Hannibal Smith'
    end

    scenario 'Escaping should work properly when entering a name' do
      members_page.visit!
      members_page.open_new_member!
      members_page.enter_principal_search! 'script'

      expect(members_page).not_to have_alert_dialog
      expect(page).to have_text "<script>alert('h4x');</script>"
    end
  end

  context 'with an impaired user' do
    before do
      admin.impaired = true
      admin.save!
    end

    it_behaves_like 'adding and removing principals'
  end

  context 'with an un-impaired user' do
    it_behaves_like 'adding and removing principals'

    # The following scenario is only tested with an unimpaired user
    # as it does not make a difference whether or not the user is impaired.

    scenario 'Escaping should work properly when selecting a user' do
      members_page.visit!
      members_page.open_new_member!
      members_page.select_principal! 'script'

      expect(members_page).not_to have_alert_dialog
      expect(page).to have_text "<script>alert('h4x');</script>"
    end
  end
end
