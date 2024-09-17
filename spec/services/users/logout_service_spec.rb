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

RSpec.describe Users::LogoutService, type: :model do
  shared_let(:user) { create(:user) }
  let(:request) { {} }
  let(:browser) do
    instance_double(Browser::Safari,
                    name: "Safari",
                    version: "13.2",
                    platform: instance_double(Browser::Platform::Linux, name: "Linux"))
  end
  let(:cookies) { {} }
  let(:controller) { instance_double(ApplicationController, browser:, cookies:) }

  let(:instance) { described_class.new(controller:) }

  subject { instance.call!(user) }

  before do
    allow(controller).to(receive(:reset_session))
  end

  describe "User.current" do
    it "resets it" do
      User.current = user

      subject

      expect(User.current).to eq User.anonymous
    end
  end

  describe "delete other sessions on destroy" do
    let!(:sessions) { create_list(:user_session, 2, user:) }
    let!(:other_session) { create(:user_session) }

    context "when config is enabled",
            with_config: { drop_old_sessions_on_logout: true } do
      it "destroys both sessions" do
        expect(Sessions::UserSession.count).to eq(3)
        expect(Sessions::UserSession.for_user(user).count).to eq(2)

        subject

        expect(Sessions::UserSession.count).to eq(1)
        expect(Sessions::UserSession.for_user(user).count).to eq(0)
      end

      describe "autologin cookie" do
        let!(:token) { create(:autologin_token, user:) }
        let!(:other_token) { create(:autologin_token, user:) }

        it "removes all autologin tokens" do
          cookies[OpenProject::Configuration.autologin_cookie_name] = token.plain_value

          subject

          expect(cookies[OpenProject::Configuration.autologin_cookie_name]).to be_nil
          expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { other_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect(Token::AutoLogin.where(user_id: user.id)).to be_empty
        end
      end
    end

    context "when config is disabled",
            with_config: { drop_old_sessions_on_logout: false } do
      it "destroys none of the existing sessions" do
        expect(Sessions::UserSession.count).to eq(3)
        expect(Sessions::UserSession.for_user(user).count).to eq(2)

        subject

        expect(Sessions::UserSession.count).to eq(3)
        expect(Sessions::UserSession.for_user(user).count).to eq(2)
      end

      describe "autologin cookie" do
        let!(:token) { create(:autologin_token, user:) }
        let!(:other_token) { create(:autologin_token, user:) }

        it "removes the matching autologin cookie and token" do
          cookies[OpenProject::Configuration.autologin_cookie_name] = token.plain_value

          subject

          expect(cookies[OpenProject::Configuration.autologin_cookie_name]).to be_nil
          expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect(Token::AutoLogin.where(user_id: user.id).all).to contain_exactly other_token
        end
      end
    end
  end
end
