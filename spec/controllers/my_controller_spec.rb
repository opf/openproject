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

RSpec.describe MyController do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe "password change" do
    describe "security" do
      render_views

      before do
        get :security
      end

      it "does render 'Change password' section" do
        expect(response.body).to have_css(".Subhead-heading", text: "Change password")
      end
    end

    describe "#password" do
      before do
        get :password
      end

      it "renders the password template" do
        assert_template "password"
        expect(response).to have_http_status(:success)
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
        expect(response).to redirect_to action: "security"
        expect(user.errors.attribute_names).to eq([:password_confirmation])
        expect(user.errors.map(&:message).flatten)
          .to contain_exactly("Password confirmation does not match password.")
      end
    end

    describe "with wrong password" do
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
        expect(response).to redirect_to action: "security"
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

      it "redirects to the security page" do
        expect(response).to redirect_to(my_security_path)
      end

      it "allows the user to login with the new password" do
        assert User.try_to_login(user.login, "adminADMIN!New")
      end
    end

    describe "with brute force protection",
             with_settings: { brute_force_block_minutes: 30, brute_force_block_after_failed_logins: 20 } do
      describe "blocks password change attempts after too many failures" do
        before do
          user.update_columns(
            failed_login_count: 20,
            last_failed_login_on: 1.minute.ago
          )

          post :change_password,
               params: {
                 password: "adminADMIN!",
                 new_password: "adminADMIN!New",
                 new_password_confirmation: "adminADMIN!New"
               }
        end

        it "blocks the attempt even with correct password" do
          expect(response).to redirect_to action: "security"
        end

        it "does not change the password" do
          user.reload
          expect(user.check_password?("adminADMIN!")).to be true
          expect(user.check_password?("adminADMIN!New")).to be false
        end
      end

      describe "logs failed password attempts" do
        before do
          user.update_columns(
            failed_login_count: 0,
            last_failed_login_on: nil
          )

          post :change_password,
               params: {
                 password: "WrongPassword!",
                 new_password: "adminADMIN!New",
                 new_password_confirmation: "adminADMIN!New"
               }
        end

        it "increments failed login count" do
          user.reload
          expect(user.failed_login_count).to eq(1)
        end

        it "updates last failed login timestamp" do
          user.reload
          expect(user.last_failed_login_on).to be_within(1.second).of(Time.zone.now)
        end
      end

      describe "resets failed login count on successful password change" do
        before do
          user.update_columns(
            failed_login_count: 5,
            last_failed_login_on: 1.minute.ago
          )

          post :change_password,
               params: {
                 password: "adminADMIN!",
                 new_password: "adminADMIN!New",
                 new_password_confirmation: "adminADMIN!New"
               }
        end

        it "resets the failed login count to zero" do
          user.reload
          expect(user.failed_login_count).to eq(0)
        end

        it "changes the password successfully" do
          user.reload
          expect(user.check_password?("adminADMIN!New")).to be true
        end
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
    end
  end

  describe "locale" do
    it "renders the locale template" do
      as_logged_in_user user do
        get :locale
      end

      expect(response).to be_successful
      expect(response).to render_template "locale"
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

  describe "updating custom field values" do
    let!(:editable_cf) { create(:user_custom_field, :string, editable: true) }
    let!(:readonly_cf) { create(:user_custom_field, :string, editable: false) }

    it "persists editable custom fields but ignores non-editable ones" do
      as_logged_in_user user do
        patch :update_settings, params: {
          user: { custom_field_values: { editable_cf.id.to_s => "ok",
                                         readonly_cf.id.to_s => "tampered" } }
        }
      end

      expect(user.reload.custom_value_for(editable_cf)&.value).to eq "ok"
      expect(user.custom_value_for(readonly_cf)&.value).to be_blank
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

  describe "interface:auto_hide_popups" do
    context "with render_views" do
      before do
        as_logged_in_user user do
          get :interface
        end
      end

      render_views
      it "renders auto hide popups checkbox" do
        expect(response.body).to have_css("form #auto_hide_popups")
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
        get :security
      end
    end

    render_views

    it "does not render 'Change password' section" do
      expect(response.body).to have_no_css(".Subhead-heading", text: "Change password")
    end
  end

  describe "#working_times" do
    let!(:user_working_hours) { create(:user_working_hours, valid_from: 1.week.ago, user:) }

    subject { get :working_hours }

    it "responds with success" do
      subject
      expect(response).to be_successful
    end

    it "renders the working_hours template" do
      subject
      expect(response).to render_template "working_hours"
    end

    it "assigns @current_working_hours and @past_working_hours" do
      subject
      expect(assigns(:current_working_hours)).to eq(user_working_hours)
      expect(assigns(:past_working_hours)).to eq([user_working_hours])
    end
  end
end
