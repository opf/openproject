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

RSpec.describe MyController, :skip_2fa_stage do
  render_views

  let(:sso_config) do
    {
      header:,
      secret:
    }
  end

  let(:header) { "X-Remote-User" }
  let(:secret) { "42" }

  let!(:ldap_auth_source) { create(:ldap_auth_source) }
  let!(:user) { create(:user, login:, ldap_auth_source:, last_login_on: 5.days.ago) }
  let(:login) { "h.wurst" }
  let(:header_login_value) { login }
  let(:header_value) { "#{header_login_value}#{secret ? ':' : ''}#{secret}" }
  let(:find_user_result) { user }

  shared_examples "should log in the user" do
    it "logs in given user" do
      expect(response).to redirect_to my_account_path
      expect(user.reload.last_login_on).to equal_time_without_usec(Time.current)
      expect(session[:user_id]).to eq user.id
    end
  end

  shared_examples "auth source sso failure" do
    it "redirects to AccountController#sso to show the error" do
      expect(response).to redirect_to "/sso"

      failure = session[:auth_source_sso_failure]

      expect(failure).to be_present
      expect(failure[:login]).to eq login
      expect(failure[:back_url]).to eq "http://test.host/my/account"
      expect(failure[:ttl]).to eq 1
    end

    context "when the config is marked optional" do
      let(:sso_config) do
        {
          header:,
          secret:,
          optional: true
        }
      end

      context "when no header is present" do
        let(:header_value) { nil }

        it "redirects to login" do
          expect(response).to redirect_to("/login?back_url=http%3A%2F%2Ftest.host%2Fmy%2Faccount")
        end
      end

      context "when the header is present" do
        it "shows an error" do
          expect(response).to redirect_to("/sso")
          expect(session).to have_key(:auth_source_sso_failure)
        end
      end
    end
  end

  before do
    if sso_config
      allow(OpenProject::Configuration)
        .to receive(:auth_source_sso)
              .and_return(sso_config)
    end

    allow(LdapAuthSource)
      .to(receive(:find_user))
      .and_return(find_user_result)

    request.headers[header] = header_value
  end

  describe "login" do
    before do
      get :account
    end

    it_behaves_like "should log in the user"

    context "when the secret being null" do
      let(:secret) { nil }

      it_behaves_like "should log in the user"
    end

    context "when the secret is a number" do
      let(:secret) { 42 }

      it_behaves_like "should log in the user"
    end

    context "when the header values does not match the case" do
      let(:header_login_value) { "H.wUrSt" }

      it_behaves_like "should log in the user"
    end

    context "when the user is invited" do
      let!(:user) do
        create(:user, login:, status: Principal.statuses[:invited], ldap_auth_source:)
      end

      it "logs in given user and activate it" do
        expect(response).to redirect_to my_account_path
        expect(user.reload).to be_active
        expect(session[:user_id]).to eq user.id
      end
    end

    context "with no auth source sso configured" do
      let(:sso_config) { nil }

      it "redirects to login" do
        expect(response).to redirect_to("/login?back_url=http%3A%2F%2Ftest.host%2Fmy%2Faccount")
      end
    end

    context "with a non-active user user" do
      let(:user) { create(:user, login:, ldap_auth_source:, status: 2) }

      it_behaves_like "auth source sso failure"
    end

    context "with an invalid user" do
      let(:ldap_auth_source) { create(:ldap_auth_source, onthefly_register: true) }

      let!(:duplicate) { create(:user, mail: "login@DerpLAP.net") }
      let(:login) { "dummy_dupuser" }

      let(:user) do
        build(:user, login:, mail: duplicate.mail, ldap_auth_source:)
      end

      it_behaves_like "auth source sso failure"
    end
  end

  context "when the logged-in user differs in case" do
    let(:header_login_value) { "h.WURST" }
    let(:session_update_time) { 1.minute.ago }
    let(:last_login) { 1.minute.ago }

    before do
      user.update_column(:last_login_on, last_login)
      session[:user_id] = user.id
      session[:updated_at] = session_update_time
      session[:should_be_kept] = true
    end

    it "logs in the user" do
      get :account

      expect(response).not_to be_redirect
      expect(response).to be_successful
      expect(session[:user_id]).to eq user.id
      expect(session[:updated_at]).to be > session_update_time

      # User not is not relogged
      expect(user.reload.last_login_on).to equal_time_without_usec(last_login)

      # Session values are kept
      expect(session[:should_be_kept]).to be true
    end
  end

  context "when the logged-in user differs from the header" do
    let(:other_user) { create(:user, login: "other_user") }
    let(:session_update_time) { 1.minute.ago }
    let(:service) { Users::LogoutService.new(controller:) }

    before do
      session[:user_id] = other_user.id
      session[:updated_at] = session_update_time
    end

    it "logs out the user and logs it in again" do
      allow(Users::LogoutService).to receive(:new).and_return(service)
      allow(service).to receive(:call!).with(other_user).and_call_original

      get :account

      expect(service).to have_received(:call!).with(other_user)
      expect(response).to redirect_to my_account_path
      expect(user.reload.last_login_on).to equal_time_without_usec(Time.current)
      expect(session[:user_id]).to eq user.id
      expect(session[:updated_at]).to be > session_update_time
    end
  end
end
