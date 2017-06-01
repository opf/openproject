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

describe 'create users', type: :feature, selenium: true do
  let(:current_user) { FactoryGirl.create :admin }
  let(:auth_source) { FactoryGirl.build :dummy_auth_source }
  let(:new_user_page) { Pages::NewUser.new }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  shared_examples_for 'successful user creation' do
    let(:mail) { ActionMailer::Base.deliveries.last }
    let(:mail_body) { mail.body.parts.first.to_s }
    let(:token) { mail_body.scan(/token=(.*)$/).first.first }

    it 'creates the user' do
      expect(page).to have_selector('.flash', text: 'Successful creation.')

      new_user = User.order('created_on DESC').first

      expect(current_path).to eql(edit_user_path(new_user.id))
    end

    it 'sends out an activation email' do
      expect(mail_body).to include 'activate your account'
      expect(token).not_to be_nil
    end
  end

  context 'with internal authentication' do
    before do
      visit new_user_path

      new_user_page.fill_in! first_name: 'bobfirst',
                             last_name: 'boblast',
                             email: 'bob@mail.com'

      new_user_page.submit!
    end

    it_behaves_like 'successful user creation' do
      describe 'activation' do
        before do
          allow(User).to receive(:current).and_call_original

          visit "/account/activate?token=#{token}"
        end

        it 'shows the registration form' do
          expect(page).to have_text 'Create a new account'
        end

        it 'registers the user upon submission' do
          fill_in 'user_password', with: 'foobarbaz1'
          fill_in 'user_password_confirmation', with: 'foobarbaz1'

          click_button 'Create'

          # landed on the 'my page'
          expect(page).to have_text 'Welcome, your account has been activated. You are logged in now.'
          expect(page).to have_link 'bobfirst boblast'
        end
      end
    end
  end

  context 'with external authentication', js: true do
    before do
      auth_source.save!

      new_user_page.visit!
      new_user_page.fill_in! first_name: 'bobfirst',
                             last_name: 'boblast',
                             email: 'bob@mail.com',
                             login: 'bob',
                             auth_source: auth_source.name

      new_user_page.submit!
    end

    it_behaves_like 'successful user creation' do
      describe 'activation', js: true do
        before do
          allow(User).to receive(:current).and_call_original

          visit "/account/activate?token=#{token}"
        end

        it 'shows the login form prompting the user to login' do
          expect(page).to have_text 'Please login as bob to activate your account.'
        end

        it 'registers the user upon submission' do
          # login is already filled with 'bob'
          fill_in 'password', with: 'dummy' # accepted by DummyAuthSource

          click_button 'Sign in'

          expect(page).to have_text 'OpenProject'
          expect(current_path).to eq '/'
          expect(page).to have_link 'bobfirst boblast'
        end
      end
    end
  end
end
