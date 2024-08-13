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

RSpec.describe MyController do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe "password change" do
    describe "#password" do
      before do
        get :password
      end

      it "renders the password template" do
        assert_template "password"
        assert_response :success
      end
    end

    describe "with disabled password login" do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
        post :change_password
      end

      it "is not found" do
        expect(response.status).to eq 404
      end
    end

    describe "with wrong confirmation" do
      before do
        post :change_password,
             params: {
               password: "adminADMIN!",
               new_password: "adminADMIN!New",
               new_password_confirmation: "adminADMIN!Other"
             }
      end

      it "shows an error message" do
        assert_response :success
        assert_template "password"
        expect(user.errors.attribute_names).to eq([:password_confirmation])
        expect(user.errors.map(&:message).flatten)
          .to contain_exactly("Password confirmation does not match password.")
      end
    end

    describe "with wrong password" do
      render_views
      before do
        @current_password = user.current_password.id
        post :change_password,
             params: {
               password: "wrongpassword",
               new_password: "adminADMIN!New",
               new_password_confirmation: "adminADMIN!New"
             }
      end

      it "shows an error message" do
        assert_response :success
        assert_template "password"
        expect(flash[:error]).to eq("Wrong password")
      end

      it "does not change the password" do
        expect(user.current_password.id).to eq(@current_password)
      end
    end

    describe "with good password and good confirmation" do
      before do
        post :change_password,
             params: {
               password: "adminADMIN!",
               new_password: "adminADMIN!New",
               new_password_confirmation: "adminADMIN!New"
             }
      end

      it "redirects to the my password page" do
        expect(response).to redirect_to("/my/password")
      end

      it "allows the user to login with the new password" do
        assert User.try_to_login(user.login, "adminADMIN!New")
      end
    end
  end

  describe "account" do
    let(:custom_field) { create(:user_custom_field, :text) }

    before do
      custom_field
      as_logged_in_user user do
        get :account
      end
    end

    it "responds with success" do
      expect(response).to be_successful
    end

    it "renders the account template" do
      expect(response).to render_template "account"
    end

    it "assigns @user" do
      expect(assigns(:user)).to eq(user)
    end

    context "with render_views" do
      render_views
      it "renders editable custom fields" do
        expect(response.body).to have_content(custom_field.name)
      end

      it "renders the 'Change password' menu entry" do
        expect(response.body).to have_css("#menu-sidebar li a", text: "Change password")
      end
    end
  end

  describe "settings" do
    describe "PATCH" do
      let(:language) { "en" }
      let(:params) do
        {
          user: { language: },
          pref: { auto_hide_popups: 0 }
        }
      end

      before do
        as_logged_in_user user do
          user.pref.comments_sorting = "desc"
          user.pref.auto_hide_popups = true

          patch :update_settings, params:
        end
      end

      it "updates the settings appropriately", :aggregate_failures do
        expect(assigns(:user).language).to eq language
        expect(assigns(:user).pref.comments_sorting).to eql "desc"
        expect(assigns(:user).pref.auto_hide_popups?).to be_falsey

        expect(request.path).to eq(my_settings_path)
        expect(flash[:notice]).to eql I18n.t(:notice_account_updated)
      end

      context "when user is invalid" do
        let(:user) do
          create(:user).tap do |u|
            u.update_column(:mail, "something invalid")
          end
        end

        it "shows a flash error" do
          expect(flash[:error]).to include "Email is not a valid email address."
          expect(request.path).to eq(my_settings_path)
        end
      end

      context "when changing language" do
        let(:language) { "de" }

        it "shows a flash message translated in the selected language" do
          expect(assigns(:user).language).to eq(language)
          expect(flash[:notice]).to eq(I18n.t(:notice_account_updated, locale: language))
        end
      end
    end
  end

  describe "changing changing mail" do
    let!(:recovery_token) { create(:recovery_token, user:) }
    let!(:plain_session) { create(:user_session, user:, session_id: "internal_foobar") }
    let!(:user_session) { Sessions::UserSession.find_by(session_id: "internal_foobar") }

    let(:params) do
      { user: { mail: "foo@example.org" } }
    end

    it "clears other sessions and removes tokens" do
      as_logged_in_user user do
        patch :update_settings, params:
      end

      expect(flash[:info]).to include(I18n.t(:notice_account_updated))
      expect(flash[:info]).to include(I18n.t(:notice_account_other_session_expired))

      expect(Token::Recovery.where(user:)).to be_empty
      expect { user_session.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "settings:auto_hide_popups" do
    context "with render_views" do
      before do
        as_logged_in_user user do
          get :settings
        end
      end

      render_views
      it "renders auto hide popups checkbox" do
        expect(response.body).to have_css("#my_account_form #pref_auto_hide_popups")
      end
    end

    context "PATCH" do
      before do
        as_logged_in_user user do
          user.pref.auto_hide_popups = false

          patch :update_settings, params: { user: { language: "en" } }
        end
      end
    end
  end

  describe "account with disabled password login" do
    before do
      allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
      as_logged_in_user user do
        get :account
      end
    end

    render_views

    it "does not render 'Change password' menu entry" do
      expect(response.body).to have_no_css("#menu-sidebar li a", text: "Change password")
    end
  end

  describe "access_tokens" do
    describe "rss" do
      it "creates a key" do
        expect(user.rss_token).to be_nil

        post :generate_rss_key
        expect(user.reload.rss_token).to be_present
        expect(flash[:info]).to be_present
        expect(flash[:error]).not_to be_present

        expect(response).to redirect_to action: :access_token
      end

      context "with existing key" do
        let!(:key) { Token::RSS.create user: }

        it "replaces the key" do
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

    describe "api" do
      context "with no existing key" do
        it "creates a key" do
          expect(user.api_tokens).to be_empty

          post :generate_api_key, params: { token_api: { token_name: "One heck of a token" } }, format: :turbo_stream
          new_token = user.reload.api_tokens.last
          expect(new_token).to be_present

          expect(response).to be_successful
          expect(response.body).to include(new_token.token_name)
        end
      end

      context "with existing key" do
        let!(:key) { Token::API.create(user:, data: { name: "One heck of a token" }) }

        it "must add the new key" do
          expect(user.reload.api_tokens.last).to eq(key)

          post :generate_api_key, params: { token_api: { token_name: "Two heck of a token" } }, format: :turbo_stream

          new_token = user.reload.api_tokens.last
          expect(new_token).not_to eq(key)
          expect(new_token.value).not_to eq(key.value)

          expect(response).to be_successful
          expect(response.body).to include("Two heck of a token")
        end
      end
    end

    describe "ical" do
      # unlike with the other tokens, creating new ical tokens is not done in this context
      # ical tokens are generated whenever the user requests a new ical url
      # a user can have N ical tokens
      #
      # in this context a specific ical token of a user should be reverted
      # this invalidates the previously generated ical url
      context "with existing keys" do
        let(:user) { create(:user) }
        let(:project) { create(:project) }
        let(:query) { create(:query, project:) }
        let(:another_query) { create(:query, project:) }
        let!(:ical_token_for_query) { create(:ical_token, user:, query:, name: "Some Token Name") }
        let!(:another_ical_token_for_query) { create(:ical_token, user:, query:, name: "Some Other Token Name") }
        let!(:ical_token_for_another_query) { create(:ical_token, user:, query: another_query, name: "Some Token Name") }

        it "revoke specific ical tokens" do
          expect(user.ical_tokens).to contain_exactly(
            ical_token_for_query, another_ical_token_for_query, ical_token_for_another_query
          )

          delete :revoke_ical_token, params: { id: another_ical_token_for_query.id }

          expect(user.ical_tokens.reload).to contain_exactly(
            ical_token_for_query, ical_token_for_another_query
          )

          expect(user.ical_tokens.reload).not_to contain_exactly(
            ical_token_for_another_query
          )

          expect(flash[:info]).to be_present
          expect(flash[:error]).not_to be_present

          expect(response).to redirect_to action: :access_token
        end
      end
    end

    describe "file storage" do
      let(:client) { create(:oauth_client, integration: create(:nextcloud_storage)) }
      let(:token) { create(:oauth_client_token, oauth_client: client, scope: nil, user:, expires_in: 3_600) }

      render_views

      before { token }

      it "list the tokens" do
        get :access_token
        expect(response.body).to have_css("#storage-oauth-token-#{token.id}")
      end

      it "can remove the token" do
        expect do
          delete :delete_storage_token, params: { id: token.id }
        end.to change(OAuthClientToken, :count).by(-1)

        expect(flash[:info]).to be_present
        expect(flash[:error]).not_to be_present
        expect(response).to redirect_to(action: :access_token)
      end
    end
  end
end
