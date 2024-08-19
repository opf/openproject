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

RSpec.describe Users::LoginService, type: :model do
  shared_let(:input_user) { create(:user) }
  let(:request) { {} }
  let(:session) { {} }
  let(:browser) do
    instance_double(Browser::Safari,
                    name: "Safari",
                    version: "13.2",
                    platform: instance_double(Browser::Platform::Linux, name: "Linux"))
  end
  let(:cookies) { {} }
  let(:flash) { ActionDispatch::Flash::FlashHash.new }
  let(:controller) { instance_double(ApplicationController, browser:, cookies:, session:, flash:) }

  let(:instance) { described_class.new(user: input_user, controller:, request:) }

  subject { instance.call! }

  before do
    allow(Sessions::DropOtherSessionsService)
      .to receive(:call!)
      .with(input_user, session)

    allow(controller)
      .to(receive(:reset_session)) do
      session.clear
      flash.clear
    end

    allow(input_user)
      .to receive(:log_successful_login)
  end

  describe "session" do
    context "with an SSO provider" do
      let(:sso_provider) do
        {
          name: "saml",
          retain_from_session: %i[foo bar]
        }
      end

      before do
        allow(OpenProject::Plugins::AuthPlugin)
          .to(receive(:find_provider_by_name))
          .with("provider_name")
          .and_return sso_provider
      end

      context "if provider retains session values" do
        let(:retained_values) { %i[foo bar] }

        it "retains present session values" do
          session[:omniauth_provider] = "provider_name"
          session[:foo] = "foo value"
          session[:what] = "should be cleared"

          subject

          expect(session[:foo]).to be_present
          expect(session[:what]).to be_nil
          expect(session[:user_id]).to eq input_user.id
        end

        context "if provider retains oidc session values" do
          let(:retained_values) { %w[omniauth.oidc_sid] }
          let(:sso_provider) do
            {
              name: "oidc",
              retain_from_session: %w[omniauth.oidc_sid]
            }
          end

          it "retains an oidc session token (Regression #52185)" do
            expect(OpenProject::Hook)
              .to receive(:call_hook) # rubocop:disable RSpec/MessageSpies
                    .with(
                      :user_logged_in,
                      {
                        request: {},
                        user: input_user,
                        session: hash_including("omniauth.oidc_sid" => "1234", user_id: input_user.id)
                      }
                    )
            session[:omniauth_provider] = "provider_name"
            session["omniauth.oidc_sid"] = "1234"

            subject

            expect(session["omniauth.oidc_sid"]).to eq "1234"
          end
        end
      end

      it "retains present flash values" do
        flash[:notice] = "bar" # rubocop:disable Rails/I18nLocaleTexts

        subject

        expect(controller.flash[:notice]).to eq "bar"
      end
    end
  end

  describe "autologin cookie" do
    before do
      session[:autologin_requested] = true if autologin_requested
    end

    shared_examples "does not set autologin cookie" do
      it "does not set a cookie" do
        subject

        expect(Token::AutoLogin.exists?(user: input_user)).to be false
        expect(cookies[OpenProject::Configuration["autologin_cookie_name"]]).to be_nil
      end
    end

    context "when not requested and disabled", with_settings: { autologin: 0 } do
      let(:autologin_requested) { false }

      it_behaves_like "does not set autologin cookie"
    end

    context "when not requested and enabled", with_settings: { autologin: 1 } do
      let(:autologin_requested) { false }

      it_behaves_like "does not set autologin cookie"
    end

    context "when requested, but disabled", with_settings: { autologin: 0 } do
      let(:autologin_requested) { true }

      it_behaves_like "does not set autologin cookie"
    end

    context "when requested and enabled", with_settings: { autologin: 1 } do
      let(:autologin_requested) { true }

      it "sets a cookie" do
        subject

        tokens = Token::AutoLogin.where(user: input_user)
        expect(tokens.count).to eq 1
        expect(tokens.first.user_id).to eq input_user.id

        autologin_cookie = cookies[OpenProject::Configuration["autologin_cookie_name"]]
        expect(autologin_cookie).to be_present
        expect(autologin_cookie[:value]).to be_present
        expect(autologin_cookie[:expires]).to eq (Time.zone.today + 1.day).beginning_of_day
        expect(autologin_cookie[:path]).to eq "/"
        expect(autologin_cookie[:httponly]).to be true
        expect(autologin_cookie[:secure]).to eq Setting.https?
        expect(Token::AutoLogin.find_by_plaintext_value(autologin_cookie[:value])).to eq tokens.first
      end
    end

    context "when requested and enabled with https",
            with_config: { https: true },
            with_settings: { autologin: 1 } do
      let(:autologin_requested) { true }

      it "sets a secure cookie" do
        subject

        autologin_cookie = cookies[OpenProject::Configuration["autologin_cookie_name"]]
        expect(autologin_cookie[:secure]).to be true
      end
    end
  end

  describe "removal of tokens" do
    let!(:invitation_token) { create(:invitation_token, user: input_user) }
    let!(:recovery_token) { create(:recovery_token, user: input_user) }

    it "removes only the recovery token on successful login" do
      subject

      expect(Token::Invitation.exists?(invitation_token.id)).to be true
      expect(Token::Recovery.exists?(recovery_token.id)).to be false
    end
  end
end
