# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe AccountController, :skip_2fa_stage do
  let(:user_hook_class) do
    Class.new(OpenProject::Hook::ViewListener) do
      attr_reader :registered_user, :first_login_user

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
  end

  let(:hook) { user_hook_class.instance }
  let(:user) { build_stubbed(:user) }

  before do
    hook.reset!
  end

  describe "GET #login" do
    let(:params) { {} }

    context "when the user is not already logged in" do
      before do
        get :login, params:
      end

      it "renders the view" do
        expect(response).to render_template "login"
        expect(response).to be_successful
      end
    end

    context "when the user is already logged in" do
      before do
        login_as user

        get :login, params:
      end

      it "redirects to home" do
        expect(response)
          .to redirect_to my_page_path
      end

      context "and a valid back url is present" do
        let(:params) { { back_url: "/projects" } }

        it "redirects to back_url value" do
          expect(response)
            .to redirect_to projects_path
        end
      end

      context "and an invalid back url present" do
        let(:params) { { back_url: "http://test.foo/work_packages/show/1" } }

        it "redirects to home" do
          expect(response).to redirect_to my_page_path
        end
      end
    end
  end

  describe "GET #internal_login" do
    shared_let(:admin) { create(:admin) }

    context "when direct login enabled", with_config: { omniauth_direct_login_provider: "some_provider" } do
      it "allows to login internally using a special route" do
        get :internal_login

        expect(response).to render_template "account/login"
      end

      it "allows to post to login" do
        post :login, params: { username: admin.login, password: "adminADMIN!" }
        expect(response).to redirect_to "/my/page"
      end
    end

    context "when direct login disabled" do
      it "the internal login route is inactive" do
        get :internal_login

        expect(response).to have_http_status(:not_found)
        expect(session[:internal_login]).not_to be_present
      end
    end
  end

  describe "POST #login" do
    shared_let(:admin) { create(:admin) }

    describe "wrong password" do
      it "redirects back to login" do
        post :login, params: { username: "admin", password: "bad" }
        expect(response).to be_successful
        expect(response).to render_template "login"
        expect(flash[:error]).to include "Invalid user or password"
      end
    end

    context "with first login" do
      before do
        admin.update first_login: true

        post :login, params: { username: admin.login, password: "adminADMIN!" }
      end

      it "redirect to default path with ?first_time_user=true" do
        expect(response).to redirect_to "/?first_time_user=true"
      end

      it "calls the user_first_login hook" do
        expect(hook.first_login_user).to eq admin
      end
    end

    context "without first login" do
      before do
        post :login, params: { username: admin.login, password: "adminADMIN!" }
      end

      it "redirect to the my page" do
        expect(response).to redirect_to "/my/page"
      end

      it "does not call the user_first_login hook" do
        expect(hook.first_login_user).to be_nil
      end
    end

    describe "User logging in with back_url" do
      it "redirects to a relative path" do
        post :login,
             params: { username: admin.login, password: "adminADMIN!", back_url: "/" }
        expect(response).to redirect_to root_path
      end

      it "redirects to an absolute path given the same host" do
        # note: test.host is the hostname during tests
        post :login,
             params: {
               username: admin.login,
               password: "adminADMIN!",
               back_url: "http://test.host/work_packages/show/1"
             }
        expect(response).to redirect_to "/work_packages/show/1"
      end

      it "does not redirect to another host" do
        post :login,
             params: {
               username: admin.login,
               password: "adminADMIN!",
               back_url: "http://test.foo/work_packages/show/1"
             }
        expect(response).to redirect_to my_page_path
      end

      it "does not redirect to another host with a protocol relative url" do
        post :login,
             params: {
               username: admin.login,
               password: "adminADMIN!",
               back_url: "//test.foo/fake"
             }
        expect(response).to redirect_to my_page_path
      end

      it "does not redirect to logout" do
        post :login,
             params: {
               username: admin.login,
               password: "adminADMIN!",
               back_url: "/logout"
             }
        expect(response).to redirect_to my_page_path
      end

      context "with a relative url root" do
        around do |example|
          old_relative_url_root = OpenProject::Configuration["rails_relative_url_root"]
          OpenProject::Configuration["rails_relative_url_root"] = "/openproject"
          example.run
        ensure
          OpenProject::Configuration["rails_relative_url_root"] = old_relative_url_root
        end

        it "redirects to the same subdirectory with an absolute path" do
          post :login,
               params: {
                 username: admin.login,
                 password: "adminADMIN!",
                 back_url: "http://test.host/openproject/work_packages/show/1"
               }
          expect(response).to redirect_to "/openproject/work_packages/show/1"
        end

        it "redirects to the same subdirectory with a relative path" do
          post :login,
               params: {
                 username: admin.login,
                 password: "adminADMIN!",
                 back_url: "/openproject/work_packages/show/1"
               }
          expect(response).to redirect_to "/openproject/work_packages/show/1"
        end

        it "does not redirect to another subdirectory with an absolute path" do
          post :login,
               params: {
                 username: admin.login,
                 password: "adminADMIN!",
                 back_url: "http://test.host/foo/work_packages/show/1"
               }
          expect(response).to redirect_to my_page_path
        end

        it "does not redirect to another subdirectory with a relative path" do
          post :login,
               params: {
                 username: admin.login,
                 password: "adminADMIN!",
                 back_url: "/foo/work_packages/show/1"
               }
          expect(response).to redirect_to my_page_path
        end

        it "does not redirect to another subdirectory by going up the path hierarchy" do
          post :login,
               params: {
                 username: admin.login,
                 password: "adminADMIN!",
                 back_url: "http://test.host/openproject/../foo/work_packages/show/1"
               }
          expect(response).to redirect_to my_page_path
        end

        it "does not redirect to another subdirectory with a protocol relative path" do
          post :login,
               params: {
                 username: admin.login,
                 password: "adminADMIN!",
                 back_url: "//test.host/foo/work_packages/show/1"
               }
          expect(response).to redirect_to my_page_path
        end
      end
    end

    describe "GET #logout" do
      shared_let(:admin) { create(:admin) }

      it "calls reset_session" do
        allow(controller).to receive(:reset_session)
        login_as admin

        get :logout

        expect(controller).to have_received(:reset_session).once
        expect(response).to be_redirect
      end

      context "with a user with an SSO provider attached" do
        let(:user) { build_stubbed(:user, login: "bob", identity_url: "saml:foo") }
        let(:slo_callback) { nil }
        let(:sso_provider) do
          { name: "saml", single_sign_out_callback: slo_callback }
        end

        before do
          allow(OpenProject::Plugins::AuthPlugin)
            .to(receive(:login_provider_for))
            .and_return(sso_provider)
          login_as user
        end

        context "with no provider" do
          it "redirects to default" do
            get :logout
            expect(response).to redirect_to home_path
          end
        end

        context "with a redirecting callback" do
          let(:slo_callback) do
            Proc.new do |prev_session, prev_user|
              if prev_session[:foo] && prev_user[:login] = "bob"
                redirect_to "/login"
              end
            end
          end

          context "with direct login and redirecting callback",
                  with_config: { omniauth_direct_login_provider: "foo" }, with_settings: { login_required?: true } do
            it "stills call the callback" do
              # Set the previous session
              session[:foo] = "bar"

              get :logout
              expect(response).to redirect_to "/login"

              # Expect session to be cleared
              expect(session[:foo]).to be_nil
            end
          end

          it "calls the callback" do
            # Set the previous session
            session[:foo] = "bar"

            get :logout
            expect(response).to redirect_to "/login"

            # Expect session to be cleared
            expect(session[:foo]).to be_nil
          end
        end

        context "with a no-op callback" do
          it "redirects to default if the callback does nothing" do
            was_called = false
            sso_provider[:single_sign_out_callback] = Proc.new do
              was_called = true
            end

            get :logout
            expect(was_called).to be true
            expect(response).to redirect_to home_path
          end
        end

        context "with a provider that does not have slo_callback" do
          let(:slo_callback) { nil }

          it "redirects to default if the callback does nothing" do
            get :logout
            expect(response).to redirect_to home_path
          end
        end
      end
    end

    describe "for a user trying to log in via an API request" do
      before do
        post :login,
             params: {
               username: admin.login,
               password: "adminADMIN!"
             },
             format: :json
      end

      it "returns a 410" do
        expect(response.code.to_s).to eql("410")
      end

      it "does not login the user" do
        expect(controller.send(:current_user)).to be_anonymous
      end
    end

    context "with disabled password login" do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

        post :login
      end

      it "is not found" do
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "#login with omniauth_direct_login enabled",
           with_config: { omniauth_direct_login_provider: "some_provider" } do
    describe "GET" do
      it "redirects to some_provider" do
        get :login

        expect(response).to redirect_to "/auth/some_provider"
      end
    end

    describe "POST" do
      shared_let(:admin) { create(:admin) }

      it "allows to login internally still" do
        post :login, params: { username: admin.login, password: "adminADMIN!" }
        expect(response).to redirect_to "/my/page"
      end
    end
  end

  describe "#login with omniauth_direct_login_provider set but empty",
           with_config: { omniauth_direct_login_provider: "" } do
    describe "GET" do
      it "does not redirect to some_provider" do
        get :login

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Login for user with forced password change" do
    let(:admin) { create(:admin, force_password_change: true) }

    before do
      allow_any_instance_of(User).to receive(:change_password_allowed?).and_return(false) # rubocop:disable RSpec/AnyInstance
    end

    describe "Missing flash data for user initiated password change" do
      before do
        post "change_password",
             flash: {
               _password_change_user_id: nil
             },
             params: {
               username: admin.login,
               password: "whatever",
               new_password: "whatever",
               new_password_confirmation: "whatever2"
             }
      end

      it "renders 404" do
        expect(response).to have_http_status :not_found
      end
    end

    describe "User who is not allowed to change password can't login" do
      before do
        post "change_password",
             params: {
               password_change_user_id: admin.id,
               username: admin.login,
               password: "adminADMIN!",
               new_password: "adminADMIN!New",
               new_password_confirmation: "adminADMIN!New"
             }
      end

      it "redirects to the login page" do
        expect(response).to redirect_to "/login"
      end
    end

    describe "User who is not allowed to change password, is not redirected to the login page" do
      before do
        post "login", params: { username: admin.login, password: "adminADMIN!" }
      end

      it "redirects to the login page" do
        expect(response).to redirect_to "/login"
      end
    end
  end

  describe "POST #change_password" do
    context "with disabled password login" do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
        post :change_password
      end

      it "is not found" do
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "POST #lost_password" do
    context "when the user has been invited but not yet activated" do
      shared_let(:admin) { create(:admin, status: :invited) }
      shared_let(:token) { create(:recovery_token, user: admin) }

      context "with a valid token" do
        before do
          post :lost_password, params: { token: token.value }
        end

        it "redirects to the login page" do
          expect(response).to redirect_to "/login"
        end
      end
    end
  end

  shared_examples "registration disabled" do
    it "redirects to back the login page" do
      expect(response).to redirect_to signin_path
    end

    it "informs the user that registration is disabled" do
      expect(flash[:error]).to eq(I18n.t("account.error_self_registration_disabled"))
    end

    it "does not call the user_registered callback" do
      expect(hook.registered_user).to be_nil
    end
  end

  describe "GET #register" do
    context "with self registration on",
            with_settings: { self_registration: Setting::SelfRegistration.automatic } do
      context "and password login enabled" do
        before do
          get :register
        end

        it "is successful" do
          expect(subject).to respond_with :success
          expect(response).to render_template :register
          expect(assigns[:user]).not_to be_nil
          expect(assigns[:user].notification_settings.size).to eq(1)
        end
      end

      context "and password login disabled" do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

          get :register
        end

        it_behaves_like "registration disabled"
      end
    end

    context "with self registration off",
            with_settings: { self_registration: Setting::SelfRegistration.disabled } do
      before do
        get :register
      end

      it_behaves_like "registration disabled"
    end

    context "with self registration off but an ongoing invitation activation",
            with_settings: { self_registration: Setting::SelfRegistration.disabled } do
      let(:token) { create(:invitation_token) }

      before do
        session[:invitation_token] = token.value

        get :register
      end

      it "is successful" do
        expect(subject).to respond_with :success
        expect(response).to render_template :register
        expect(assigns[:user]).not_to be_nil
      end
    end
  end

  # See integration/account_test.rb for the full test
  describe "POST #register" do
    context "with self registration on automatic",
            with_settings: { self_registration: Setting::SelfRegistration.automatic } do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)
      end

      context "with password login enabled" do
        # expects `redirect_to_path`
        shared_examples "automatic self registration succeeds" do
          before do
            post :register,
                 params: {
                   user: {
                     login: "register",
                     password: "adminADMIN!",
                     password_confirmation: "adminADMIN!",
                     firstname: "John",
                     lastname: "Doe",
                     mail: "register@example.com"
                   }
                 }
          end

          it "redirects to the expected path" do
            expect(subject).to respond_with :redirect
            expect(assigns[:user]).not_to be_nil
            expect(subject).to redirect_to(redirect_to_path)
            expect(User.where(login: "register").last).not_to be_nil
          end

          it "set the user status to active" do
            user = User.where(login: "register").last
            expect(user).not_to be_nil
            expect(user).to be_active
          end

          it "calls the user_registered callback" do
            user = hook.registered_user

            expect(user.mail).to eq "register@example.com"
            expect(user).to be_active
          end
        end

        it_behaves_like "automatic self registration succeeds" do
          let(:redirect_to_path) { "/?first_time_user=true" }

          it "calls the user_first_login callback" do
            user = hook.first_login_user

            expect(user.mail).to eq "register@example.com"
          end
        end

        context "with user limit reached" do
          let!(:admin) { create(:admin) }

          let(:params) do
            {
              user: {
                login: "register",
                password: "adminADMIN!",
                password_confirmation: "adminADMIN!",
                firstname: "John",
                lastname: "Doe",
                mail: "register@example.com"
              }
            }
          end

          before do
            allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(true)

            post :register, params:
          end

          it "fails" do
            expect(subject).to redirect_to(signin_path)

            expect(flash[:error]).to match /user limit reached/
          end

          it "notifies the admins about the issue" do
            perform_enqueued_jobs

            mail = ActionMailer::Base.deliveries.detect { |m| m.to.first == admin.mail }
            expect(mail).to be_present
            expect(mail.subject).to match /limit reached/
            expect(mail.body.parts.first.to_s).to match /new user \(#{params[:user][:mail]}\)/
          end

          it "does not call the user_registered callback" do
            expect(hook.registered_user).to be_nil
          end
        end
      end

      context "with password login disabled" do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

          post :register
        end

        it_behaves_like "registration disabled"
      end
    end

    context "with self registration by email",
            with_settings: { self_registration: Setting::SelfRegistration.by_email } do
      context "with password login enabled" do
        before do
          Token::Invitation.delete_all
          post :register,
               params: {
                 user: {
                   login: "register",
                   password: "adminADMIN!",
                   password_confirmation: "adminADMIN!",
                   firstname: "John",
                   lastname: "Doe",
                   mail: "register@example.com"
                 }
               }
        end

        it "redirects to the login page" do
          expect(subject).to redirect_to "/login"
        end

        it "doesn't activate the user but sends out a token instead" do
          expect(User.find_by_login("register")).not_to be_active
          token = Token::Invitation.last
          expect(token.user.mail).to eq("register@example.com")
          expect(token).not_to be_expired
        end

        it "calls the user_registered callback" do
          user = hook.registered_user

          expect(user.mail).to eq "register@example.com"
          expect(user).to be_registered
        end
      end

      context "with password login disabled" do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

          post :register
        end

        it_behaves_like "registration disabled"
      end
    end

    context "with manual activation",
            with_settings: { self_registration: Setting::SelfRegistration.manual } do
      let(:user_hash) do
        { login: "register",
          password: "adminADMIN!",
          password_confirmation: "adminADMIN!",
          firstname: "John",
          lastname: "Doe",
          mail: "register@example.com" }
      end

      context "without back_url" do
        before do
          post :register, params: { user: user_hash }
        end

        it "redirects to the login page" do
          expect(response).to redirect_to "/login"
        end

        it "doesn't activate the user" do
          expect(User.find_by_login("register")).not_to be_active
        end

        it "calls the user_registered callback" do
          user = hook.registered_user

          expect(user.mail).to eq "register@example.com"
          expect(user).to be_registered
        end
      end

      context "with back_url" do
        before do
          post :register, params: { user: user_hash, back_url: "https://example.net/some_back_url" }
        end

        it "preserves the back url" do
          expect(response).to redirect_to("/login?back_url=https%3A%2F%2Fexample.net%2Fsome_back_url")
        end

        it "calls the user_registered callback" do
          user = hook.registered_user

          expect(user.mail).to eq "register@example.com"
          expect(user).to be_registered
        end
      end

      context "with password login disabled" do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

          post :register
        end

        it_behaves_like "registration disabled"
      end
    end

    context "with self registration off",
            with_settings: { self_registration: Setting::SelfRegistration.disabled } do
      before do
        post :register,
             params: {
               user: {
                 login: "register",
                 password: "adminADMIN!",
                 password_confirmation: "adminADMIN!",
                 firstname: "John",
                 lastname: "Doe",
                 mail: "register@example.com"
               }
             }
      end

      it_behaves_like "registration disabled"
    end

    context "with on-the-fly registration",
            with_settings: { self_registration: Setting::SelfRegistration.disabled } do
      before do
        allow_any_instance_of(User).to receive(:change_password_allowed?).and_return(false) # rubocop:disable RSpec/AnyInstance
      end

      context "with password login disabled" do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
        end

        describe "registration" do
          before do
            post :register,
                 params: {
                   user: {
                     firstname: "Foo",
                     lastname: "Smith",
                     mail: "foo@bar.com"
                   }
                 }
          end

          it_behaves_like "registration disabled"
        end
      end
    end
  end

  describe "POST #activate" do
    describe "account activation" do
      shared_examples "account activation" do
        let(:token) { Token::Invitation.create user: }

        let(:activation_params) do
          {
            token: token.value
          }
        end

        context "with an expired token" do
          before do
            token.update_column :expires_on, 1.day.ago

            post :activate, params: activation_params
          end

          it "fails and shows an expiration warning" do
            expect(subject).to redirect_to("/")
            expect(flash[:warning]).to include "expired"
          end

          it "deletes the old token and generates a new one" do
            old_token = Token::Invitation.find_by(id: token.id)
            new_token = Token::Invitation.find_by(user_id: token.user.id)

            expect(old_token).to be_nil
            expect(new_token).to be_present

            expect(new_token).not_to be_expired
          end

          it "sends out a new activation email" do
            new_token = Token::Invitation.find_by(user_id: token.user.id)

            perform_enqueued_jobs

            mail = ActionMailer::Base.deliveries.last
            expect(mail.parts.first.body.raw_source).to include "activate?token=#{new_token.value}"
          end
        end
      end

      context "with an invited user" do
        it_behaves_like "account activation" do
          let(:user) { create(:user, status: 4) }
        end
      end

      context "with a registered user" do
        it_behaves_like "account activation" do
          let(:user) { create(:user, status: 2) }
        end
      end
    end

    describe "user limit" do
      let!(:admin) { create(:admin) }
      let(:user) { create(:user, status:) }
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

          mail = ActionMailer::Base.deliveries.detect { |m| m.to.first == admin.mail }
          expect(mail).to be_present
          expect(mail.subject).to match /limit reached/
        end
      end

      context "with an invited user" do
        let(:status) { User.statuses[:invited] }

        it_behaves_like "activation is blocked due to user limit"
      end

      context "with a registered user" do
        let(:status) { User.statuses[:registered] }

        it_behaves_like "activation is blocked due to user limit"
      end
    end
  end

  describe "GET #auth_source_sso_failed (/sso)" do
    render_views

    let(:failure) do
      {
        login:,
        back_url: "/my/account",
        ttl: 1
      }
    end

    let(:ldap_auth_source) { create(:ldap_auth_source) }
    let(:user) { create(:user, status: 2, ldap_auth_source:) }
    let(:login) { user.login }

    before do
      session[:auth_source_sso_failure] = failure
    end

    context "with a non-active user" do
      it "shows the non-active error message" do
        get :auth_source_sso_failed

        expect(session[:auth_source_sso_failure]).not_to be_present

        expect(response.body)
          .to have_text "Your account has not yet been activated."
        expect(response.body)
          .to have_text "Single Sign-On (SSO) for user '#{user.login}' failed"
      end
    end

    context "with an invalid user" do
      let!(:duplicate) { create(:user, mail: "login@DerpLAP.net") }
      let(:login) { "foo" }
      let(:attrs) do
        { mail: duplicate.mail, login:, firstname: "bla", lastname: "bar" }
      end

      before do
        allow(LdapAuthSource).to receive(:get_user_attributes).and_return attrs
      end

      it "shows the account creation form with an error" do
        get :auth_source_sso_failed

        expect(session[:auth_source_sso_failure]).not_to be_present

        expect(response.body).to have_text "Create a new account"
        expect(response.body).to have_text "This field is invalid: Email has already been taken."
      end
    end

    context "with a missing email" do
      let!(:duplicate) { create(:user, mail: "login@DerpLAP.net") }
      let(:login) { "foo" }
      let(:attrs) do
        { login:, firstname: "bla", lastname: "bar" }
      end

      before do
        allow(LdapAuthSource).to receive(:get_user_attributes).and_return attrs
      end

      it "shows the account creation form with an error" do
        get :auth_source_sso_failed

        expect(session[:auth_source_sso_failure]).not_to be_present

        expect(response.body).to have_text "Create a new account"
        expect(response.body).to have_text "This field is invalid: Email can't be blank."
      end
    end
  end
end
