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

describe 'Omniauth authentication', type: :feature do
  let(:user) do
    FactoryGirl.create(:user,
                       force_password_change: false,
                       identity_url: 'developer:omnibob@example.com',
                       login: 'omnibob',
                       mail: 'omnibob@example.com',
                       firstname: 'omni',
                       lastname: 'bob'
                      )
  end

  before do
    @omniauth_test_mode = OmniAuth.config.test_mode
    @capybara_ignore_elements = Capybara.ignore_hidden_elements
    @omniauth_logger = OmniAuth.config.logger
    OmniAuth.config.logger = Rails.logger
    Capybara.ignore_hidden_elements = false
  end

  after do
    User.delete_all
    User.current = nil
    OmniAuth.config.test_mode = @omniauth_test_mode
    Capybara.ignore_hidden_elements = @capybara_ignore_elements
    OmniAuth.config.logger = @omniauth_logger
  end

  ##
  # Returns a given translation up until the first occurrence of a parameter (exclusive).
  def translation_substring(translation)
    translation.scan(/(^.*) %\{/).first.first
  end

  context 'sign in existing user' do
    it 'should redirect to back url' do
      visit account_lost_password_path
      click_link("Omniauth Developer", :match => :first)
      fill_in('first_name', with: user.firstname)
      fill_in('last_name', with: user.lastname)
      fill_in('email', with: user.mail)
      click_link_or_button 'Sign In'

      expect(current_url).to eql account_lost_password_url
    end

    it 'should sign in user' do
      visit '/auth/developer'
      fill_in('first_name', with: user.firstname)
      fill_in('last_name', with: user.lastname)
      fill_in('email', with: user.mail)
      click_link_or_button 'Sign In'

      expect(page).to have_link('omni bob')
      expect(page).to have_link('Sign out')
    end

    context 'with direct login',
            with_config: { omniauth_direct_login_provider: 'developer' } do

      it 'should go directly to the developer sign in and then redirect to the back url' do
        url = 'http://www.example.com/my/account'

        visit url
        # requires login, redirects to developer login which is why we see the login form now

        fill_in('first_name', with: user.firstname)
        fill_in('last_name', with: user.lastname)
        fill_in('email', with: user.mail)
        click_link_or_button 'Sign In'

        expect(current_url).to eql url
      end
    end
  end

  describe 'sign out a user with direct login and login required',
           with_config: { omniauth_direct_login_provider: 'developer' },
           with_settings: { login_required?: true } do

    it 'shows a notice that the user has been logged out' do
      visit signout_path

      expect(page).to have_content(I18n.t(:notice_logged_out))
      expect(page).to have_content translation_substring(I18n.t(:instructions_after_logout))
    end

    it 'sign-in after previous sign-out shows my page' do
      visit signout_path

      expect(page).to have_content(I18n.t(:notice_logged_out))

      click_on 'here'

      fill_in('first_name', with: user.firstname)
      fill_in('last_name', with: user.lastname)
      fill_in('email', with: user.mail)
      click_link_or_button 'Sign In'

      expect(current_url).to eq my_page_url
    end
  end

  shared_examples 'omniauth user registration' do
    it 'should register new user' do
      visit '/'
      click_link("Omniauth Developer", :match => :first)

      # login form developer strategy
      fill_in('first_name', with: user.firstname)
      # intentionally do not supply last_name
      fill_in('email', with: user.mail)
      click_link_or_button 'Sign In'

      # on register form, we are prompted for a last name
      within('#content') do
        fill_in('user_lastname', with: user.lastname)
        click_link_or_button 'Create'
      end

      expect(page).to have_content(I18n.t(:notice_account_registered_and_logged_in))
      expect(page).to have_link('Sign out')
    end
  end

  context 'register on the fly',
           with_settings: {
            self_registration?: true,
            self_registration: '3',
            available_languages: [:en]
           } do

    let(:user) do
      User.new(force_password_change: false,
               identity_url: 'developer:omnibob@example.com',
               login: 'omnibob',
               mail: 'omnibob@example.com',
               firstname: 'omni',
               lastname: 'bob')
    end

    it_behaves_like 'omniauth user registration'

    it 'should redirect to homesceen' do
      visit account_lost_password_path
      click_link("Omniauth Developer", :match => :first)

      # login form developer strategy
      fill_in('first_name', with: user.firstname)
      # intentionally do not supply last_name
      fill_in('email', with: user.mail)
      click_link_or_button 'Sign In'

      # on register form, we are prompted for a last name
      within('#content') do
        fill_in('user_lastname', with: user.lastname)
        click_link_or_button 'Create'
      end

      expect(current_url).to eql home_url(first_time_user: true)
    end

    context 'with password login disabled',
            with_config: { disabled_password_login: 'true' } do

      it_behaves_like 'omniauth user registration'
    end
  end

  context 'registration by email',
          with_settings: {
            self_registration?: true,
            self_registration: '1'
          } do

    shared_examples 'registration with registration by email' do
      it 'shows a note explaining that the account has to be activated' do
        visit login_path

        # login form developer strategy
        fill_in 'first_name', with: 'Ifor'
        fill_in 'last_name',  with: 'McAlistar'
        fill_in 'email',      with: 'i.mcalistar@example.com'

        click_link_or_button 'Sign In'

        expect(page).to have_content(I18n.t(:notice_account_register_done))

        if defined? instructions
          expect(page).to have_content instructions
        end
      end
    end

    it_behaves_like 'registration with registration by email' do
      let(:login_path) { '/auth/developer' }
    end

    context 'with direct login enabled and login required',
            with_config: { omniauth_direct_login_provider: 'developer' } do

      before do
        allow(Setting).to receive(:login_required?).and_return(true)
      end

      it_behaves_like 'registration with registration by email' do
        # i.e. it still shows a notice
        # instead of redirecting straight back to the omniauth login provider
        let(:login_path) { signin_path }
        let(:instructions) { translation_substring I18n.t(:instructions_after_registration) }
      end
    end
  end

  context 'error occurs' do
    shared_examples 'omniauth signin error' do
      it 'should fail with generic error message' do
        # set omniauth to test mode will redirect all calls to omniauth
        # directly to the callback and by setting the mock_auth provider
        # to a symbol will force omniauth to fail /auth/failure
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:developer] = :invalid_credentials
        visit login_path
        expect(page).to have_content(I18n.t(:error_external_authentication_failed))

        if defined? instructions
          expect(page).to have_content instructions
        end
      end
    end

    it_behaves_like 'omniauth signin error' do
      let(:login_path) { '/auth/developer' }
    end

    context 'with direct login and login required',
            with_config: { omniauth_direct_login_provider: 'developer' } do

      before do
        allow(Setting).to receive(:login_required?).and_return(true)
      end

      it_behaves_like 'omniauth signin error' do
        let(:login_path) { signin_path }
        let(:instructions) { translation_substring I18n.t(:instructions_after_error) }
      end
    end
  end
end
