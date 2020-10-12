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

describe MyController, type: :controller do
  let(:user) { FactoryBot.create(:user) }

  before(:each) do
    login_as(user)
  end

  describe 'password change' do
    describe '#password' do
      before do
        get :password
      end

      it 'should render the password template' do
        assert_template 'password'
        assert_response :success
      end
    end

    describe 'with disabled password login' do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
        post :change_password
      end

      it 'is not found' do
        expect(response.status).to eq 404
      end
    end

    describe 'with wrong confirmation' do
      before do
        post :change_password,
             params: {
               password: 'adminADMIN!',
               new_password: 'adminADMIN!New',
               new_password_confirmation: 'adminADMIN!Other'
             }
      end
      it 'should show an error message' do
        assert_response :success
        assert_template 'password'
        expect(user.errors.keys).to eq([:password_confirmation])
        expect(user.errors.values.flatten.join('')).to include("doesn't match")
      end
    end

    describe 'with wrong password' do
      render_views
      before do
        @current_password = user.current_password.id
        post :change_password,
             params: {
               password: 'wrongpassword',
               new_password: 'adminADMIN!New',
               new_password_confirmation: 'adminADMIN!New'
             }
      end

      it 'should show an error message' do
        assert_response :success
        assert_template 'password'
        expect(flash[:error]).to eq('Wrong password')
      end

      it 'should not change the password' do
        expect(user.current_password.id).to eq(@current_password)
      end
    end

    describe 'with good password and good confirmation' do
      before do
        post :change_password,
             params: {
               password: 'adminADMIN!',
               new_password: 'adminADMIN!New',
               new_password_confirmation: 'adminADMIN!New'
             }
      end

      it 'should redirect to the my password page' do
        expect(response).to redirect_to('/my/password')
      end

      it 'should allow the user to login with the new password' do
        assert User.try_to_login(user.login, 'adminADMIN!New')
      end
    end
  end

  describe 'account' do
    let(:custom_field) { FactoryBot.create :text_user_custom_field }
    before do
      custom_field
      as_logged_in_user user do
        get :account
      end
    end

    it 'responds with success' do
      expect(response).to be_successful
    end

    it 'renders the account template' do
      expect(response).to render_template 'account'
    end

    it 'assigns @user' do
      expect(assigns(:user)).to eq(user)
    end

    context 'with render_views' do
      render_views
      it 'renders editable custom fields' do
        expect(response.body).to have_content(custom_field.name)
      end

      it "renders the 'Change password' menu entry" do
        expect(response.body).to have_selector('#menu-sidebar li a', text: 'Change password')
      end
    end
  end

  describe 'settings' do
    context 'PATCH' do
      before do
        as_logged_in_user user do
          user.pref.self_notified = false

          patch :update_settings, params: { user: { language: 'en' } }
        end
      end

      it 'does not alter the email preferences' do
        expect(assigns(:user).pref.self_notified?).to be_falsey
      end

      it 'redirects to settings' do
        expect(request.path).to eq(my_settings_path)
      end

      it 'has a successful flash' do
        expect(flash[:notice]).to eql I18n.t(:notice_account_updated)
      end

      context 'when user is invalid' do
        let(:user) do
          FactoryBot.create(:user).tap do |u|
            u.update_column(:mail, 'something invalid')
          end
        end

        it 'shows a flash error' do
          expect(flash[:error]).to include 'Email is invalid.'
          expect(request.path).to eq(my_settings_path)
        end
      end
    end
  end

  describe 'settings:auto_hide_popups' do
    context 'with render_views' do
      before do
        as_logged_in_user user do
          get :settings
        end
      end

      render_views
      it 'renders auto hide popups checkbox' do
        expect(response.body).to have_selector('#my_account_form #pref_auto_hide_popups')
      end
    end

    context 'PATCH' do
      before do
        as_logged_in_user user do
          user.pref.auto_hide_popups = false

          patch :update_settings, params: { user: { language: 'en' } }
        end
      end
    end
  end

  describe 'account with disabled password login' do
    before do
      allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
      as_logged_in_user user do
        get :account
      end
    end

    render_views

    it "does not render 'Change password' menu entry" do
      expect(response.body).not_to have_selector('#menu-sidebar li a', text: 'Change password')
    end
  end

  describe 'access_tokens' do
    describe 'rss' do
      it 'creates a key' do
        expect(user.rss_token).to eq(nil)

        post :generate_rss_key
        expect(user.reload.rss_token).to be_present
        expect(flash[:info]).to be_present
        expect(flash[:error]).not_to be_present

        expect(response).to redirect_to action: :access_token
      end

      context 'with existing key' do
        let!(:key) { ::Token::RSS.create user: user }

        it 'replaces the key' do
          expect(user.rss_token).to eq(key)

          post :generate_rss_key
          new_token = user.reload.rss_token
          expect(new_token).not_to eq(key)
          expect(new_token.value).not_to eq(key.value)
          expect(new_token.value).to eq(user.rss_key)

          expect(flash[:info]).to be_present
          expect(flash[:error]).not_to be_present
          expect(response).to redirect_to action: :access_token
        end
      end
    end

    describe 'api' do
      context 'with no existing key' do
        it 'creates a key' do
          expect(user.api_token).to eq(nil)

          post :generate_api_key
          new_token = user.reload.api_token
          expect(new_token).to be_present

          expect(flash[:info]).to be_present
          expect(flash[:error]).not_to be_present

          expect(response).to redirect_to action: :access_token
        end
      end

      context 'with existing key' do
        let!(:key) { ::Token::API.create user: user }

        it 'replaces the key' do
          expect(user.reload.api_token).to eq(key)

          post :generate_api_key

          new_token = user.reload.api_token
          expect(new_token).not_to eq(key)
          expect(new_token.value).not_to eq(key.value)
          expect(flash[:info]).to be_present
          expect(flash[:error]).not_to be_present

          expect(response).to redirect_to action: :access_token
        end
      end
    end
  end
end
