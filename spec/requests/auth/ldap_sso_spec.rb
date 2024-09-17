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

RSpec.describe "LDAP authentication",
               :skip_2fa_stage,
               :skip_csrf,
               type: :rails_request do
  include_context "with temporary LDAP"

  let(:username) { "aa729" }
  let(:password) { "smada" }
  let(:params) { { username:, password: } }

  subject do
    post(signin_path, params:)
    response
  end

  context "when LDAP is onthefly_register" do
    let(:onthefly_register) { true }

    it "creates the user on the fly" do
      expect(User.find_by(login: "aa729")).to be_nil

      expect { subject }.to change(User.not_builtin.active, :count).by(1)

      user = User.find_by(login: "aa729")
      expect(user).to be_present
      expect(user).to be_active
      expect(session[:user_id]).to eq user.id
      expect(subject).to redirect_to "/?first_time_user=true"
    end

    context "with a user that has umlauts in their name" do
      let(:username) { "bölle" }
      let(:password) { "bólle" }

      it "creates a user with umlauts on the fly" do
        expect(User.find_by(login: "bölle")).to be_nil

        expect { subject }.to change(User.not_builtin.active, :count).by(1)

        user = User.find_by(login: "bölle")
        expect(user).to be_present
        expect(user).to be_active
        expect(session[:user_id]).to eq user.id
        expect(subject).to redirect_to "/?first_time_user=true"
      end
    end

    context "when not all attributes present" do
      let(:attr_mail) { nil }

      it "does not save the user, but forwards to registration form" do
        expect(User.find_by(login: "aa729")).to be_nil

        expect { subject }.not_to change(User.not_builtin.active, :count)
        expect(subject).to render_template "account/register"
        expect(subject.body).to have_text "Email can't be blank"
      end
    end

    context "with user limit reached" do
      before do
        allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(true)
      end

      it "shows the user limit error" do
        expect(subject.body).to have_text "User limit reached"
        expect(subject.body).to include "/account/register"
      end
    end

    context "with password login disabled" do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
      end

      describe "login" do
        it "is not found" do
          expect(subject).to have_http_status :not_found
        end
      end
    end
  end
end
