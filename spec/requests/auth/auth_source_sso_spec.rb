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

RSpec.describe AuthSourceSSO, :skip_2fa_stage, # Prevent redirects to 2FA stage
               type: :rails_request do
  let(:sso_config) do
    {
      header: "X-Remote-User",
      optional: true
    }
  end

  before do
    allow(OpenProject::Configuration)
      .to receive(:auth_source_sso)
            .and_return(sso_config)
  end

  include_context "with temporary LDAP"

  context "when LDAP is onthefly_register" do
    let(:onthefly_register) { true }

    it "creates the user on the fly" do
      expect(User.find_by(login: "aa729")).to be_nil

      expect do
        get "/projects", headers: { "X-Remote-User" => "aa729" }
      end.to change(User.not_builtin, :count).by(1)

      user = User.find_by(login: "aa729")
      expect(user).to be_present
      expect(user).to be_active
      expect(session[:user_id]).to eq user.id
      expect(session[:user_from_auth_header]).to eq true
      expect(response).to redirect_to "/projects"
    end
  end

  context "when LDAP is not onthefly_register" do
    let(:onthefly_register) { false }

    it "returns an error when the user does not exist" do
      get "/projects", headers: { "X-Remote-User" => "nonexistent" }

      expect(response).to redirect_to "/sso"
      expect(session[:auth_source_sso_failure]).to be_present
    end

    context "when the user exists, but is outdated" do
      let(:user) { create(:user, login: "ldap_admin", admin: false, ldap_auth_source:) }

      it "redirects the user to that URL" do
        expect(user).not_to be_admin
        get "/projects?foo=bar", headers: { "X-Remote-User" => user.login }
        expect(response).to redirect_to "/projects?foo=bar"

        user.reload
        expect(user).to be_admin
      end
    end

    context "when the user exists in another auth source that is inaccessible" do
      let(:other_ldap) { create(:ldap_auth_source, name: "other_ldap") }
      let(:user) { create(:user, login: "ldap_admin", admin: false, ldap_auth_source: other_ldap) }

      it "returns an error when the user does not exist" do
        get "/projects", headers: { "X-Remote-User" => "nonexistent" }

        expect(response).to redirect_to "/sso"
        expect(session[:auth_source_sso_failure]).to be_present
      end
    end
  end
end
