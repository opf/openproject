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

describe AccountController, type: :controller do
  after do
    User.delete_all
    User.current = nil
  end
  let(:user) { FactoryGirl.build_stubbed(:user) }

  context 'GET #login' do
    let(:setup) {}
    let(:params) { {} }

    before do
      setup

      get :login, params: params
    end

    it 'renders the view' do
      expect(response).to render_template 'login'
      expect(response).to be_success
    end

    context 'user already logged in' do
      let(:setup) { login_as user }

      it 'redirects to home' do
        expect(response)
          .to redirect_to my_page_path
      end
    end

    context 'user already logged in and back url present' do
      let(:setup) { login_as user }
      let(:params) { { back_url: "/projects" } }

      it 'redirects to back_url value' do
        expect(response)
          .to redirect_to projects_path
      end
    end

    context 'user already logged in and invalid back url present' do
      let(:setup) { login_as user }
      let(:params) { { back_url: 'http://test.foo/work_packages/show/1' } }

      it 'redirects to home' do
        expect(response).to redirect_to my_page_path
      end
    end
  end

  context 'POST #login' do
    let(:admin) { FactoryGirl.create(:admin) }

    describe 'wrong password' do
      it 'redirects back to login' do
        post :login, params: { username: 'admin', password: 'bad' }
        expect(response).to be_success
        expect(response).to render_template 'login'
        expect(flash[:error]).to include 'Invalid user or password'
      end
    end

    describe 'User logging in with back_url' do
      it 'should redirect to a relative path' do
        post :login,
             params: { username: admin.login, password: 'adminADMIN!', back_url: '/' }
        expect(response).to redirect_to root_path
      end

      it 'should redirect to an absolute path given the same host' do
        # note: test.host is the hostname during tests
        post :login,
             params: {
               username: admin.login,
               password: 'adminADMIN!',
               back_url: 'http://test.host/work_packages/show/1'
             }
        expect(response).to redirect_to '/work_packages/show/1'
      end

      it 'should not redirect to another host' do
        post :login,
             params: {
               username: admin.login,
               password: 'adminADMIN!',
               back_url: 'http://test.foo/work_packages/show/1'
             }
        expect(response).to redirect_to my_page_path
      end

      it 'should not redirect to another host with a protocol relative url' do
        post :login,
             params: {
               username: admin.login,
               password: 'adminADMIN!',
               back_url: '//test.foo/fake'
             }
        expect(response).to redirect_to my_page_path
      end

      it 'should not redirect to logout' do
        post :login,
             params: {
               username: admin.login,
               password: 'adminADMIN!',
               back_url: '/logout'
             }
        expect(response).to redirect_to my_page_path
      end

      it 'should create users on the fly' do
        allow(Setting).to receive(:self_registration).and_return('0')
        allow(Setting).to receive(:self_registration?).and_return(false)
        allow(AuthSource).to receive(:authenticate).and_return(login: 'foo',
                                                               firstname: 'Foo',
                                                               lastname: 'Smith',
                                                               mail: 'foo@bar.com',
                                                               auth_source_id: 66)
        post :login, params: { username: 'foo', password: 'bar' }

        expect(response).to redirect_to home_url(first_time_user: true)
        user = User.find_by_login('foo')
        expect(user).to be_an_instance_of User
        expect(user.auth_source_id).to eq(66)
        expect(user.current_password).to be_nil
      end

      context 'with a relative url root' do
        before do
          @old_relative_url_root = OpenProject::Configuration['rails_relative_url_root']
          OpenProject::Configuration['rails_relative_url_root'] = '/openproject'
        end

        after do
          OpenProject::Configuration['rails_relative_url_root'] = @old_relative_url_root
        end

        it 'should redirect to the same subdirectory with an absolute path' do
          post :login,
               params: {
                 username: admin.login,
                 password: 'adminADMIN!',
                 back_url: 'http://test.host/openproject/work_packages/show/1'
               }
          expect(response).to redirect_to '/openproject/work_packages/show/1'
        end

        it 'should redirect to the same subdirectory with a relative path' do
          post :login,
               params: {
                 username: admin.login,
                 password: 'adminADMIN!',
                 back_url: '/openproject/work_packages/show/1'
               }
          expect(response).to redirect_to '/openproject/work_packages/show/1'
        end

        it 'should not redirect to another subdirectory with an absolute path' do
          post :login,
               params: {
                 username: admin.login,
                 password: 'adminADMIN!',
                 back_url: 'http://test.host/foo/work_packages/show/1'
               }
          expect(response).to redirect_to my_page_path
        end

        it 'should not redirect to another subdirectory with a relative path' do
          post :login,
               params: {
                 username: admin.login,
                 password: 'adminADMIN!',
                 back_url: '/foo/work_packages/show/1'
               }
          expect(response).to redirect_to my_page_path
        end

        it 'should not redirect to another subdirectory by going up the path hierarchy' do
          post :login,
               params: {
                 username: admin.login,
                 password: 'adminADMIN!',
                 back_url: 'http://test.host/openproject/../foo/work_packages/show/1'
               }
          expect(response).to redirect_to my_page_path
        end

        it 'should not redirect to another subdirectory with a protocol relative path' do
          post :login,
               params: {
                 username: admin.login,
                 password: 'adminADMIN!',
                 back_url: '//test.host/foo/work_packages/show/1'
               }
          expect(response).to redirect_to my_page_path
        end
      end
    end

    context 'GET #logout' do
      let(:admin) { FactoryGirl.create(:admin) }

      it 'calls reset_session' do
        expect(@controller).to receive(:reset_session).once

        login_as admin
        get :logout
        expect(response).to be_redirect
      end
    end

    describe 'for a user trying to log in via an API request' do
      before do
        post :login,
             params: {
               username: admin.login,
               password: 'adminADMIN!'
             },
             format: :json
      end

      it 'should return a 410' do
        expect(response.code.to_s).to eql('410')
      end

      it 'should not login the user' do
        expect(@controller.send(:current_user).anonymous?).to be_truthy
      end
    end

    context 'with disabled password login' do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

        post :login
      end

      it 'is not found' do
        expect(response.status).to eq 404
      end
    end
  end

  describe '#login with omniauth_direct_login enabled',
            with_config: { omniauth_direct_login_provider: 'some_provider' } do

    describe 'GET' do
      it 'redirects to some_provider' do
        get :login

        expect(response).to redirect_to '/auth/some_provider'
      end
    end

    describe 'POST' do
      it 'redirects to some_provider' do
        post :login, params: { username: 'foo', password: 'bar' }

        expect(response).to redirect_to '/auth/some_provider'
      end
    end
  end

  describe 'Login for user with forced password change' do
    let(:admin) { FactoryGirl.create(:admin, force_password_change: true) }

    before do
      allow_any_instance_of(User).to receive(:change_password_allowed?).and_return(false)
    end

    describe "User who is not allowed to change password can't login" do
      before do
        post 'change_password',
             params: {
               username: admin.login,
               password: 'adminADMIN!',
               new_password: 'adminADMIN!New',
               new_password_confirmation: 'adminADMIN!New'
             }
      end

      it 'should redirect to the login page' do
        expect(response).to redirect_to '/login'
      end
    end

    describe 'User who is not allowed to change password, is not redirected to the login page' do
      before do
        post 'login', params: { username: admin.login, password: 'adminADMIN!' }
      end

      it 'should redirect ot the login page' do
        expect(response).to redirect_to '/login'
      end
    end
  end

  describe 'POST #change_password' do
    context 'with disabled password login' do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
        post :change_password
      end

      it 'is not found' do
        expect(response.status).to eq 404
      end
    end
  end

  shared_examples 'registration disabled' do
    it 'redirects to back the login page' do
      expect(response).to redirect_to signin_path
    end

    it 'informs the user that registration is disabled' do
      expect(flash[:error]).to eq(I18n.t('account.error_self_registration_disabled'))
    end
  end

  context 'GET #register' do
    context 'with self registration on' do
      before do
        allow(Setting).to receive(:self_registration).and_return('3')
      end

      context 'and password login enabled' do
        before do
          get :register
        end

        it 'is successful' do
          is_expected.to respond_with :success
          expect(response).to render_template :register
          expect(assigns[:user]).not_to be_nil
        end
      end

      context 'and password login disabled' do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

          get :register
        end

        it_behaves_like 'registration disabled'
      end
    end

    context 'with self registration off' do
      before do
        allow(Setting).to receive(:self_registration).and_return('0')
        allow(Setting).to receive(:self_registration?).and_return(false)
        get :register
      end

      it_behaves_like 'registration disabled'
    end

    context 'with self registration off but an ongoing invitation activation' do
      let(:token) { FactoryGirl.create :invitation_token }

      before do
        allow(Setting).to receive(:self_registration).and_return('0')
        allow(Setting).to receive(:self_registration?).and_return(false)
        session[:invitation_token] = token.value

        get :register
      end

      it 'is successful' do
        is_expected.to respond_with :success
        expect(response).to render_template :register
        expect(assigns[:user]).not_to be_nil
      end
    end
  end

  # See integration/account_test.rb for the full test
  context 'POST #register' do
    context 'with self registration on automatic' do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)
        allow(Setting).to receive(:self_registration).and_return('3')
      end

      context 'with password login enabled' do
        # expects `redirect_to_path`
        shared_examples 'automatic self registration succeeds' do
          before do
            post :register,
                 params: {
                   user: {
                     login: 'register',
                     password: 'adminADMIN!',
                     password_confirmation: 'adminADMIN!',
                     firstname: 'John',
                     lastname: 'Doe',
                     mail: 'register@example.com'
                   }
                 }
          end

          it 'redirects to my page' do
            is_expected.to respond_with :redirect
            expect(assigns[:user]).not_to be_nil
            is_expected.to redirect_to(redirect_to_path)
            expect(User.where(login: 'register').last).not_to be_nil
          end

          it 'set the user status to active' do
            user = User.where(login: 'register').last
            expect(user).not_to be_nil
            expect(user.status).to eq(User::STATUSES[:active])
          end
        end

        context "with user limit reached" do
          before do
            allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(true)
          end

          it "fails" do
            post :register,
                 params: {
                   user: {
                     login: 'register',
                     password: 'adminADMIN!',
                     password_confirmation: 'adminADMIN!',
                     firstname: 'John',
                     lastname: 'Doe',
                     mail: 'register@example.com'
                   }
                 }

            is_expected.to redirect_to(signin_path)

            expect(flash[:error]).to match /user limit reached/
          end
        end
      end

      context 'with password login disabled' do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

          post :register
        end

        it_behaves_like 'registration disabled'
      end
    end

    context 'with self registration by email' do
      before do
        allow(Setting).to receive(:self_registration).and_return('1')
      end

      context 'with password login enabled' do
        before do
          Token::Invitation.delete_all
          post :register,
               params: {
                 user: {
                   login: 'register',
                   password: 'adminADMIN!',
                   password_confirmation: 'adminADMIN!',
                   firstname: 'John',
                   lastname: 'Doe',
                   mail: 'register@example.com'
                 }
               }
        end

        it 'redirects to the login page' do
          is_expected.to redirect_to '/login'
        end

        it "doesn't activate the user but sends out a token instead" do
          expect(User.find_by_login('register')).not_to be_active
          token = Token::Invitation.last
          expect(token.user.mail).to eq('register@example.com')
          expect(token).not_to be_expired
        end
      end

      context 'with password login disabled' do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

          post :register
        end

        it_behaves_like 'registration disabled'
      end
    end

    context 'with manual activation' do
      let(:user_hash) do
        { login: 'register',
          password: 'adminADMIN!',
          password_confirmation: 'adminADMIN!',
          firstname: 'John',
          lastname: 'Doe',
          mail: 'register@example.com' }
      end

      before do
        allow(Setting).to receive(:self_registration).and_return('2')
      end

      context 'without back_url' do
        before do
          post :register, params: { user: user_hash }
        end

        it 'redirects to the login page' do
          expect(response).to redirect_to '/login'
        end

        it "doesn't activate the user" do
          expect(User.find_by_login('register')).not_to be_active
        end
      end

      context 'with back_url' do
        before do
          post :register, params: { user: user_hash, back_url: 'https://example.net/some_back_url' }
        end

        it 'preserves the back url' do
          expect(response).to redirect_to(
            '/login?back_url=https%3A%2F%2Fexample.net%2Fsome_back_url')
        end
      end

      context 'with password login disabled' do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

          post :register
        end

        it_behaves_like 'registration disabled'
      end
    end

    context 'with self registration off' do
      before do
        allow(Setting).to receive(:self_registration).and_return('0')
        allow(Setting).to receive(:self_registration?).and_return(false)
        post :register,
             params: {
               user: {
                 login: 'register',
                 password: 'adminADMIN!',
                 password_confirmation: 'adminADMIN!',
                 firstname: 'John',
                 lastname: 'Doe',
                 mail: 'register@example.com'
               }
             }
      end

      it_behaves_like 'registration disabled'
    end

    context 'with on-the-fly registration' do
      before do
        allow(Setting).to receive(:self_registration).and_return('0')
        allow(Setting).to receive(:self_registration?).and_return(false)
        allow_any_instance_of(User).to receive(:change_password_allowed?).and_return(false)
        allow(AuthSource).to receive(:authenticate).and_return(login: 'foo',
                                                               lastname: 'Smith',
                                                               auth_source_id: 66)
      end

      context 'with password login enabled' do
        before do
          post :login, params: { username: 'foo', password: 'bar' }
        end

        it 'registers the user on-the-fly' do
          is_expected.to respond_with :success
          expect(response).to render_template :register

          post :register,
               params: {
                 user: {
                   firstname: 'Foo',
                   lastname: 'Smith',
                   mail: 'foo@bar.com'
                 }
               }
          expect(response).to redirect_to '/my/account'

          user = User.find_by_login('foo')

          expect(user).to be_an_instance_of(User)
          expect(user.auth_source_id).to eql 66
          expect(user.current_password).to be_nil
        end
      end

      context 'with password login disabled' do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
        end

        describe 'login' do
          before do
            post :login, params: { username: 'foo', password: 'bar' }
          end

          it 'is not found' do
            expect(response.status).to eq 404
          end
        end

        describe 'registration' do
          before do
            post :register,
                 params: {
                   user: {
                     firstname: 'Foo',
                     lastname: 'Smith',
                     mail: 'foo@bar.com'
                   }
                 }
          end

          it_behaves_like 'registration disabled'
        end
      end
    end
  end

  context 'POST activate' do
    let(:user) { FactoryGirl.create :user, status: status }
    let(:status) { -1 }

    let(:token) { Token::Invitation.create!(user_id: user.id) }

    before do
      allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(true)

      post :activate, params: { token: token.value }
    end

    shared_examples "activation is blocked due to user limit" do
      it "does not activate the user" do
        expect(user.reload).not_to be_active
      end

      it "redirects back to the login page and shows the user limit error" do
        expect(response).to redirect_to(signin_path)
        expect(flash[:error]).to match /user limit reached.*contact.*admin/i
      end
    end

    context 'registered user' do
      let(:status) { User::STATUSES[:registered] }

      it_behaves_like "activation is blocked due to user limit"
    end

    context 'invited user' do
      let(:status) { User::STATUSES[:invited] }

      it_behaves_like "activation is blocked due to user limit"
    end
  end

  describe 'GET #auth_source_sso_failed (/sso)' do
   render_views

    let(:failure) do
      {
        user: user,
        login: user.login,
        back_url: '/my/account',
        ttl: 1
      }
    end

    let(:user) { FactoryGirl.create :user, status: 2 }

    before do
      session[:auth_source_sso_failure] = failure
    end

    context "with a non-active user" do
      it "should show the non-active error message" do
        get :auth_source_sso_failed

        expect(session[:auth_source_sso_failure]).not_to be_present

        expect(response.body)
          .to have_text "Your account has not yet been activated."
        expect(response.body)
          .to have_text "Single Sign-On (SSO) for user '#{user.login}' failed"
      end
    end

    context "with an invalid user" do
      let!(:duplicate) { FactoryGirl.create :user, mail: "login@DerpLAP.net" }
      let(:user) do
        FactoryGirl.build(:user, mail: duplicate.mail).tap(&:valid?)
      end

      it "should show the account creation form with an error" do
        get :auth_source_sso_failed

        expect(session[:auth_source_sso_failure]).not_to be_present

        expect(response.body).to have_text "Create a new account"
        expect(response.body).to have_text "This field is invalid: Email has already been taken."
      end
    end
  end
end
