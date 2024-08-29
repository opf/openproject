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

# Concern is included into AccountController and depends on methods available there
RSpec.describe AccountController, :skip_2fa_stage do # rubocop:disable RSpec/SpecFilePathFormat
  let(:omniauth_strategy) { double("Google Strategy", name: "google") } # rubocop:disable RSpec/VerifiedDoubles
  let(:omniauth_hash) do
    OmniAuth::AuthHash.new(
      provider: "google",
      strategy: omniauth_strategy,
      uid: "123545",
      info: { name: "foo",
              email: "foo@bar.com",
              first_name: "foo",
              last_name: "bar" }
    )
  end

  before do
    request.env["omniauth.auth"] = omniauth_hash
    request.env["omniauth.strategy"] = omniauth_strategy
  end

  after do
    User.current = nil
  end

  describe "GET #omniauth_login", with_settings: { self_registration: Setting::SelfRegistration.automatic } do
    context "with on-the-fly registration" do
      context "when providing all required fields" do
        before do
          request.env["omniauth.origin"] = "https://example.net/some_back_url"
          post :omniauth_login, params: { provider: :google }
        end

        it "registers the user on-the-fly" do
          user = User.find_by_login("foo@bar.com")
          expect(user).to be_an_instance_of(User)
          expect(user.ldap_auth_source_id).to be_nil
          expect(user.current_password).to be_nil
          expect(user.identity_url).to eql("google:123545")
          expect(user.login).to eql("foo@bar.com")
          expect(user.firstname).to eql("foo")
          expect(user.lastname).to eql("bar")
          expect(user.mail).to eql("foo@bar.com")
        end

        it "redirects to the first login page with a back_url" do
          expect(response).to redirect_to(home_url(first_time_user: true))
        end
      end

      describe "strategy uid mapping override" do
        let(:omniauth_hash) do
          OmniAuth::AuthHash.new(
            provider: "google",
            strategy: omniauth_strategy,
            uid: "foo",
            info: {
              uid: "internal",
              email: "whattheheck@example.com",
              first_name: "what",
              last_name: "theheck"
            }
          )
        end

        it "takes the uid from the mapped attributes" do
          post :omniauth_login, params: { provider: :google }

          user = User.find_by_login("whattheheck@example.com")
          expect(user).to be_an_instance_of(User)
          expect(user.identity_url).to eq "google:internal"
        end
      end

      describe "strategy attribute mapping override" do
        let(:omniauth_hash) do
          OmniAuth::AuthHash.new(
            provider: "google",
            strategy: omniauth_strategy,
            uid: "foo",
            info: { email: "whattheheck@example.com",
                    first_name: "what",
                    last_name: "theheck" },
            extra: { raw_info: {
              real_uid: "bar@example.org",
              first_name: "foo",
              last_name: "bar"
            } }
          )
        end

        describe "available" do
          it "merges the strategy mapping" do
            allow(omniauth_strategy).to receive(:omniauth_hash_to_user_attributes) do |auth|
              raw_info = auth[:extra][:raw_info]
              {
                login: raw_info[:real_uid],
                firstname: raw_info[:first_name],
                lastname: raw_info[:last_name]
              }
            end

            post :omniauth_login, params: { provider: :google }

            user = User.find_by_login("bar@example.org")
            expect(user).to be_an_instance_of(User)
            expect(user.firstname).to eql("foo")
            expect(user.lastname).to eql("bar")

            expect(omniauth_strategy).to have_received(:omniauth_hash_to_user_attributes)
          end
        end

        describe "unavailable" do
          it "keeps the default mapping" do
            post :omniauth_login, params: { provider: :google }

            user = User.find_by_login("whattheheck@example.com")
            expect(user).to be_an_instance_of(User)
            expect(user.firstname).to eql("what")
            expect(user.lastname).to eql("theheck")
          end
        end
      end

      context "when not providing all required fields" do
        let(:omniauth_hash) do
          OmniAuth::AuthHash.new(
            provider: "google",
            uid: "123545",
            info: { name: "foo", email: "foo@bar.com" }
            # first_name and last_name not set
          )
        end

        it "renders user form" do
          post :omniauth_login, params: { provider: :google }
          expect(response).to render_template :register
          expect(assigns(:user).mail).to eql("foo@bar.com")
        end

        it "registers user via post" do
          allow(OpenProject::OmniAuth::Authorization).to receive(:after_login!)

          auth_source_registration = omniauth_hash.merge(
            omniauth: true,
            timestamp: Time.current
          )
          session[:auth_source_registration] = auth_source_registration
          post :register,
               params: {
                 user: {
                   login: "login@bar.com",
                   firstname: "Foo",
                   lastname: "Smith",
                   mail: "foo@bar.com"
                 }
               }
          expect(response).to redirect_to home_url(first_time_user: true)

          user = User.find_by_login("login@bar.com")
          expect(OpenProject::OmniAuth::Authorization)
            .to have_received(:after_login!).with(user, a_hash_including(omniauth_hash), any_args)
          expect(user).to be_an_instance_of(User)
          expect(user.ldap_auth_source_id).to be_nil
          expect(user.current_password).to be_nil
          expect(user.identity_url).to eql("google:123545")
        end

        context "when after a timeout expired" do
          before do
            session[:auth_source_registration] = omniauth_hash.merge(
              omniauth: true,
              timestamp: 42.days.ago
            )
          end

          it "does not register the user when providing all the missing fields" do
            post :register,
                 params: {
                   user: {
                     firstname: "Foo",
                     lastname: "Smith",
                     mail: "foo@bar.com"
                   }
                 }

            expect(response).to redirect_to signin_path
            expect(flash[:error]).to eq(I18n.t(:error_omniauth_registration_timed_out))
            expect(User.find_by_login("foo@bar.com")).to be_nil
          end
        end
      end

      context "with self-registration disabled",
              with_settings: { self_registration: Setting::SelfRegistration.disabled } do
        let(:omniauth_hash) do
          OmniAuth::AuthHash.new(
            provider: "google",
            uid: "123",
            info: { name: "foo",
                    email: "foo@bar.com",
                    first_name: "foo",
                    last_name: "bar" }
          )
        end

        before do
          request.env["omniauth.origin"] = "https://example.net/some_back_url"

          post :omniauth_login, params: { provider: :google }
        end

        it "shows a notice about the activated account", :aggregate_failures do
          expect(flash[:notice]).to eq(I18n.t("notice_account_registered_and_logged_in"))
          user = User.last

          expect(user.firstname).to eq "foo"
          expect(user.lastname).to eq "bar"
          expect(user.mail).to eq "foo@bar.com"
          expect(user).to be_active
        end
      end
    end

    describe "login" do
      let(:omniauth_hash) do
        OmniAuth::AuthHash.new(
          provider: "google",
          uid: "123545",
          info: { name: "foo",
                  last_name: "bar",
                  email: "foo@bar.com" }
        )
      end

      let(:user) do
        build(:user, force_password_change: false,
                     identity_url: "google:123545")
      end

      context "with an active account" do
        before do
          user.save!
        end

        it "signs in the user after successful external authentication" do
          post :omniauth_login, params: { provider: :google }

          expect(response).to redirect_to my_page_path
        end

        it "logs a successful login" do
          post_at = Time.now.utc
          post :omniauth_login, params: { provider: :google }

          user.reload
          expect(user.last_login_on.utc.to_i).to be >= post_at.utc.to_i
        end

        context "with a back_url present" do
          before do
            request.env["omniauth.origin"] = "http://test.host/projects"
            post :omniauth_login, params: { provider: :google }
          end

          it "redirects to that url", :aggregate_failures do
            expect(response).to redirect_to "/projects"
          end
        end

        context "with a back_url from a login path" do
          before do
            request.env["omniauth.origin"] = "http://test.host/login"
            post :omniauth_login, params: { provider: :google }
          end

          it "redirects to that url", :aggregate_failures do
            expect(response).to redirect_to "/my/page"
          end
        end

        context "with a partially blank auth_hash" do
          let(:omniauth_hash) do
            OmniAuth::AuthHash.new(
              provider: "google",
              uid: "123545",
              info: { name: "foo",
                      first_name: "",
                      last_name: "newLastname",
                      email: "foo@bar.com" }
            )
          end

          it "signs in the user after successful external authentication" do
            expect { post :omniauth_login, params: { provider: :google } }
                .not_to change { user.reload.firstname }

            expect(response).to redirect_to my_page_path

            expect(user.lastname).to eq "newLastname"
          end
        end

        describe "authorization" do
          let(:config) do
            Struct.new(:google_name, :global_email).new "foo", "foo@bar.com"
          end

          before do
            allow(OpenProject::OmniAuth::Authorization).to receive(:after_login!)

            OpenProject::OmniAuth::Authorization.callbacks.clear

            # Let's set up a couple of authorization callbacks to see if the mechanism
            # works as intended.

            OpenProject::OmniAuth::Authorization.authorize_user provider: :google do |dec, auth|
              if auth.info.name == config.google_name
                dec.approve
              else
                dec.reject "Go away #{auth.info.name}!"
              end
            end

            OpenProject::OmniAuth::Authorization.authorize_user do |dec, auth|
              if auth.info.email == config.global_email
                dec.approve
              else
                dec.reject "I only want to see #{config[:global_email]} here."
              end
            end

            # ineffective callback
            OpenProject::OmniAuth::Authorization.authorize_user provider: :foobar do |dec, _|
              dec.reject "Though shalt not pass!"
            end

            # free for all callback
            OpenProject::OmniAuth::Authorization.authorize_user do |dec, _|
              dec.approve
            end
          end

          after do
            OpenProject::OmniAuth::Authorization.callbacks.clear
          end

          it "logs in the user" do
            post :omniauth_login, params: { provider: :google }

            expect(response).to redirect_to my_page_path
            expect(OpenProject::OmniAuth::Authorization)
              .to have_received(:after_login!).with(user, omniauth_hash, any_args)
          end

          context "with wrong email address" do
            before do
              config.global_email = "other@mail.com"
            end

            it "is rejected against google" do
              post :omniauth_login, params: { provider: :google }

              expect(response).to redirect_to signin_path
              expect(flash[:error]).to eq "I only want to see other@mail.com here."

              expect(OpenProject::OmniAuth::Authorization).not_to have_received(:after_login!).with(user, any_args)
            end

            it "is rejected against any other provider too" do
              omniauth_hash.provider = "any other"
              post :omniauth_login, params: { provider: :google }

              expect(response).to redirect_to signin_path
              expect(flash[:error]).to eq "I only want to see other@mail.com here."

              expect(OpenProject::OmniAuth::Authorization).not_to have_received(:after_login!).with(user, any_args)
            end
          end

          context "with the wrong name" do
            render_views

            before do
              config.google_name = "hans"
            end

            it "is rejected against google" do
              post :omniauth_login, params: { provider: :google }

              expect(response).to redirect_to signin_path
              expect(flash[:error]).to eq "Go away foo!"

              expect(OpenProject::OmniAuth::Authorization).not_to have_received(:after_login!).with(user, any_args)
            end

            it "is approved against any other provider" do
              omniauth_hash.provider = "some other"

              post :omniauth_login, params: { provider: :google }

              expect(response).to redirect_to home_url(first_time_user: true)

              # The authorization is successful which results in the registration
              # of a new user in this case because we changed the provider
              # and there isn't a user with that identity URL yet.
              new_user = User.find_by identity_url: "some other:123545"
              expect(OpenProject::OmniAuth::Authorization)
                .to have_received(:after_login!).with(new_user, any_args)
            end

            # ... and to confirm that, here's what happens when the authorization fails
            it "is rejected against any other provider with the wrong email" do
              omniauth_hash.provider = "yet another"
              config.global_email = "yarrrr@joro.es"

              post :omniauth_login, params: { provider: :google }

              expect(response).to redirect_to signin_path
              expect(flash[:error]).to eq "I only want to see yarrrr@joro.es here."
              expect(OpenProject::OmniAuth::Authorization).not_to have_received(:after_login!).with(user, any_args)
            end
          end
        end
      end

      context "with a registered and not activated accout",
              with_settings: { self_registration: Setting::SelfRegistration.by_email } do
        before do
          user.register
          user.save!

          post :omniauth_login, params: { provider: :google }
        end

        it "shows a notice about the activated account", :aggregate_failures do
          expect(flash[:notice]).to eq(I18n.t("notice_account_registered_and_logged_in"))
          expect(user.reload).to be_active
        end
      end

      context "with an invited user and self registration disabled",
              with_settings: { self_registration: Setting::SelfRegistration.disabled } do
        before do
          user.invite
          user.save!

          post :omniauth_login, params: { provider: :google }
        end

        it "shows a notice about the activated account", :aggregate_failures do
          expect(flash[:notice]).to eq(I18n.t("notice_account_registered_and_logged_in"))
          expect(user.reload).to be_active
        end
      end

      context "with a locked account",
              with_settings: { brute_force_block_after_failed_logins: 0 } do
        before do
          user.lock
          user.save!

          post :omniauth_login, params: { provider: :google }
        end

        it "shows an error indicating a failed login", :aggregate_failures do
          expect(flash[:error]).to eql(I18n.t(:notice_account_invalid_credentials))
          expect(response).to redirect_to signin_path
        end
      end
    end

    describe "with an invalid auth_hash" do
      let(:omniauth_hash) do
        OmniAuth::AuthHash.new(
          provider: "google",
          # id is deliberately missing here to make the auth_hash invalid
          info: { name: "foo",
                  email: "foo@bar.com" }
        )
      end

      before do
        post :omniauth_login, params: { provider: :google }
      end

      it "responds with an error" do
        expect(flash[:error]).to include "The authentication information returned from the identity provider was invalid."
        expect(response).to redirect_to signin_path
      end

      it "does not sign in the user" do
        expect(controller.send(:current_user)).not_to be_logged
      end

      it "does not set registration information in the session" do
        expect(session[:auth_source_registration]).to be_nil
      end
    end

    describe "Error occurs during authentication" do
      it "redirects to login page" do
        post :omniauth_failure
        expect(response).to redirect_to signin_path
      end

      it "logs a warn message" do
        allow(Rails.logger).to receive(:warn)
        post :omniauth_failure, params: { message: "invalid_credentials" }

        expect(Rails.logger).to have_received(:warn).with("invalid_credentials")
      end
    end
  end
end
