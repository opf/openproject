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

describe AccountController, type: :controller do

  class UserHook < Redmine::Hook::ViewListener
    attr_reader :registered_user
    attr_reader :first_login_user

    def user_registered(context)
      @registered_user = context[:user]
    end

    def user_first_login(context)
      @first_login_user = context[:user]
    end

    def reset!
      @registered_user = nil
      @first_login_user = nil
    end
  end

  let(:hook) { UserHook.instance }

  before do
    hook.reset!
  end

  let(:user) { FactoryBot.build_stubbed(:user) }

  context 'GET #login' do
    let(:setup) {}
    let(:params) { {} }

    before do
      setup

      get :login, params: params
    end

    it 'renders the view' do
      expect(response).to render_template 'login'
      expect(response).to be_successful
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
    using_shared_fixtures :admin

    describe 'wrong password' do
      it 'redirects back to login' do
        post :login, params: { username: 'admin', password: 'bad' }
        expect(response).to be_successful
        expect(response).to render_template 'login'
        expect(flash[:error]).to include 'Invalid user or password'
      end
    end

    context 'with first login' do
      before do
        admin.update first_login: true

        post :login, params: { username: admin.login, password: 'adminADMIN!' }
      end

      it 'redirect to default path with ?first_time_user=true' do
        expect(response).to redirect_to "/?first_time_user=true"
      end

      it 'calls the user_first_login hook' do
        expect(hook.first_login_user).to eq admin
      end
    end

    context 'without first login' do
      before do
        post :login, params: { username: admin.login, password: 'adminADMIN!' }
      end

      it 'redirect to the my page' do
        expect(response).to redirect_to "/my/page"
      end

      it 'does not call the user_first_login hook' do
        expect(hook.first_login_user).to be_nil
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
      using_shared_fixtures :admin

      it 'calls reset_session' do
        expect(@controller).to receive(:reset_session).once

        login_as admin
        get :logout
        expect(response).to be_redirect
      end

      context 'with a user with an SSO provider attached' do
        let(:user) { FactoryBot.build_stubbed :user, login: 'bob', identity_url: 'saml:foo' }
        let(:slo_callback) { nil }
        let(:sso_provider) do
          { name: 'saml',  single_sign_out_callback: slo_callback }
        end

        before do
          allow(::OpenProject::Plugins::AuthPlugin)
            .to(receive(:login_provider_for))
            .and_return(sso_provider)
          login_as user
        end

        context 'with no provider' do
          it 'will redirect to default' do
            get :logout
            expect(response).to redirect_to home_path
          end
        end

        context 'with a redirecting callback' do
          let(:slo_callback) do
            Proc.new do |prev_session, prev_user|
              if prev_session[:foo] && prev_user[:login] = 'bob'
                redirect_to '/login'
              end
            end
          end

          context 'with direct login and redirecting callback',
                  with_settings: { login_required?: true },
                  with_config: { omniauth_direct_login_provider: 'foo' } do

            it 'will still call the callback' do
              # Set the previous session
              session[:foo] = 'bar'

              get :logout
              expect(response).to redirect_to '/login'

              # Expect session to be cleared
              expect(session[:foo]).to eq nil
            end
          end

          it 'will call the callback' do
            # Set the previous session
            session[:foo] = 'bar'

            get :logout
            expect(response).to redirect_to '/login'

            # Expect session to be cleared
            expect(session[:foo]).to eq nil
          end
        end

        context 'with a no-op callback' do
          it 'will redirect to default if the callback does nothing' do
            was_called = false
            sso_provider[:single_sign_out_callback] = Proc.new {
              was_called = true
            }

            get :logout
            expect(was_called).to eq true
            expect(response).to redirect_to home_path
          end
        end

        context 'with a provider that does not have slo_callback' do
          let(:slo_callback) { nil }

          it 'will redirect to default if the callback does nothing' do
            get :logout
            expect(response).to redirect_to home_path
          end
        end
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

    context 'with an auth source' do
      let(:auth_source_id) { 42 }

      let(:user_attributes) do
        {
          login: 's.scallywag',
          firstname: 'Scarlet',
          lastname: 'Scallywag',
          mail: 's.scallywag@openproject.com',
          auth_source_id: auth_source_id
        }
      end

      let(:authenticate) { true }

      before do
        allow(Setting).to receive(:self_registration).and_return('0')
        allow(Setting).to receive(:self_registration?).and_return(false)
        allow(AuthSource).to receive(:authenticate).and_return(authenticate ? user_attributes : nil)

        # required so that the register view can be rendered
        allow_any_instance_of(User).to receive(:change_password_allowed?).and_return(false)
      end

      context 'with user limit reached' do
        render_views

        before do
          allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(true)

          post :login, params: { username: 'foo', password: 'bar' }
        end

        it 'shows the user limit error' do
          expect(response.body).to have_text "user limit reached"
        end

        it 'renders the register form' do
          expect(response.body).to include "/account/register"
        end
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
    let(:admin) { FactoryBot.create(:admin, force_password_change: true) }

    before do
      allow_any_instance_of(User).to receive(:change_password_allowed?).and_return(false)
    end


    describe "Missing flash data for user initiated password change" do
      before do
        post 'change_password',
             flash: {
               _password_change_user_id: nil
             },
             params: {
               username: admin.login,
               password: 'whatever',
               new_password: 'whatever',
               new_password_confirmation: 'whatever2'
             }
      end

      it 'should render 404' do
        expect(response.status).to eq 404
      end
    end

    describe "User who is not allowed to change password can't login" do
      before do
        post 'change_password',
             params: {
               password_change_user_id: admin.id,
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

    it 'does not call the user_registered callback' do
      expect(hook.registered_user).to be_nil
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
      let(:token) { FactoryBot.create :invitation_token }

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

          it 'redirects to the expected path' do
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

          it 'calls the user_registered callback' do
            user = hook.registered_user

            expect(user.mail).to eq "register@example.com"
            expect(user).to be_active
          end
        end

        it_behaves_like 'automatic self registration succeeds' do
          let(:redirect_to_path) { "/?first_time_user=true" }

          it "calls the user_first_login callback" do
            user = hook.first_login_user

            expect(user.mail).to eq "register@example.com"
          end
        end

        context "with user limit reached" do
          let!(:admin) { FactoryBot.create :admin }

          let(:params) do
            {
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

          before do
            allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(true)

            post :register, params: params
          end

          it "fails" do
            is_expected.to redirect_to(signin_path)

            expect(flash[:error]).to match /user limit reached/
          end

          it "notifies the admins about the issue" do
            perform_enqueued_jobs

            mail = ActionMailer::Base.deliveries.detect { |mail| mail.to.first == admin.mail }
            expect(mail).to be_present
            expect(mail.subject).to match /limit reached/
            expect(mail.body.parts.first.to_s).to match /new user \(#{params[:user][:mail]}\)/
          end

          it 'does not call the user_registered callback' do
            expect(hook.registered_user).to be_nil
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

        it 'calls the user_registered callback' do
          user = hook.registered_user

          expect(user.mail).to eq "register@example.com"
          expect(user).to be_registered
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

        it 'calls the user_registered callback' do
          user = hook.registered_user

          expect(user.mail).to eq "register@example.com"
          expect(user).to be_registered
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

        it 'calls the user_registered callback' do
          user = hook.registered_user

          expect(user.mail).to eq "register@example.com"
          expect(user).to be_registered
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
    let!(:admin) { FactoryBot.create :admin }
    let(:user) { FactoryBot.create :user, status: status }
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

      it "notifies the admins about the issue" do
        perform_enqueued_jobs

        mail = ActionMailer::Base.deliveries.detect { |mail| mail.to.first == admin.mail }
        expect(mail).to be_present
        expect(mail.subject).to match /limit reached/
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

    let(:user) { FactoryBot.create :user, status: 2 }

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
      let!(:duplicate) { FactoryBot.create :user, mail: "login@DerpLAP.net" }
      let(:user) do
        FactoryBot.build(:user, mail: duplicate.mail).tap(&:valid?)
      end

      it "should show the account creation form with an error" do
        get :auth_source_sso_failed

        expect(session[:auth_source_sso_failure]).not_to be_present

        expect(response.body).to have_text "Create a new account"
        expect(response.body).to have_text "This field is invalid: Email has already been taken."
      end
    end
  end

  describe 'POST #activate' do
    shared_examples 'account activation' do
      let(:token) { Token::Invitation.create user: user }

      let(:activation_params) do
        {
          token: token.value
        }
      end

      context 'with an expired token' do
        before do
          token.update_column :expires_on, Date.today - 1.day

          post :activate, params: activation_params
        end

        it 'fails and shows an expiration warning' do
          is_expected.to redirect_to('/')
          expect(flash[:warning]).to include 'expired'
        end

        it 'deletes the old token and generates a new one' do
          old_token = Token::Invitation.find_by(id: token.id)
          new_token = Token::Invitation.find_by(user_id: token.user.id)

          expect(old_token).to be_nil
          expect(new_token).to be_present

          expect(new_token).not_to be_expired
        end

        it 'sends out a new activation email' do
          new_token = Token::Invitation.find_by(user_id: token.user.id)

          perform_enqueued_jobs

          mail = ActionMailer::Base.deliveries.last
          expect(mail.parts.first.body.raw_source).to include "activate?token=#{new_token.value}"
        end
      end
    end

    context 'with an invited user' do
      it_behaves_like 'account activation' do
        let(:user) { FactoryBot.create :user, status: 4 }
      end
    end

    context 'with an registered user' do
      it_behaves_like 'account activation' do
        let(:user) { FactoryBot.create :user, status: 2 }
      end
    end
  end
end
