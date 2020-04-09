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

feature 'invite user via email', type: :feature, js: true do
  using_shared_fixtures :admin
  let!(:project) { FactoryBot.create :project, name: 'Project 1', identifier: 'project1' }
  let!(:developer) { FactoryBot.create :role, name: 'Developer' }

  let(:members_page) { Pages::Members.new project.identifier }

  before do
    allow(User).to receive(:current).and_return admin
  end

  context 'with a new user' do
    before do
      @old_value = Capybara.raise_server_errors
      Capybara.raise_server_errors = false
    end

    after do
      Capybara.raise_server_errors = @old_value
    end

    scenario 'adds the invited user to the project' do
      members_page.visit!
      click_on 'Add member'

      members_page.search_and_select_principal! 'finkelstein@openproject.com',
                                                'Invite finkelstein@openproject.com'
      members_page.select_role! 'Developer'
      expect(members_page).to have_selected_new_principal('Invite finkelstein@openproject.com')

      click_on 'Add'

      expect(members_page).to have_added_user('finkelstein @openproject.com')

      expect(members_page).to have_user 'finkelstein @openproject.com'

      # Should show the invited user on the default filter as well
      members_page.visit!
      expect(members_page).to have_user 'finkelstein @openproject.com'

    end
  end

  context 'with a registered user' do
    let!(:user) do
      FactoryBot.create :user, mail: 'hugo@openproject.com',
                         login: 'hugo@openproject.com',
                         firstname: 'Hugo',
                         lastname: 'Hurried'
    end

    scenario 'user lookup by email' do
      members_page.visit!
      click_on 'Add member'

      members_page.search_and_select_principal! 'hugo@openproject.com',
                                                'Hugo Hurried'
      members_page.select_role! 'Developer'

      click_on 'Add'
      expect(members_page).to have_added_user 'Hugo Hurried'
    end

    context 'who is already a member' do
      before do
        project.add_member! user, [developer]
      end

      shared_examples 'no user to invite is found' do
        scenario 'no matches found' do
          members_page.visit!
          click_on 'Add member'

          members_page.search_principal! 'hugo@openproject.com'
          expect(members_page).to have_no_search_results
        end
      end

      it_behaves_like 'no user to invite is found'

      ##
      # This is a edge case where the email address to be invited is free in principle
      # but there is a user with that email address as their login. Due to this the email address
      # cannot be used after all as the login is the same as the email address for new users
      # which means the login for this invited user will already by taken.
      # Accordingly it should not be offered to invite a user with that email address.
      context 'with different email but email as login' do
        before do
          user.mail = 'foo@bar.de'
          user.save!
        end

        it_behaves_like 'no user to invite is found'
      end
    end
  end
end
