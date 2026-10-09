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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++
require "spec_helper"

RSpec.describe OpenProject::OpenIDConnect::SessionMapper do
  let(:session) do
    instance_double(ActionDispatch::Request::Session,
                    id: instance_double(Rack::Session::SessionId, private_id: 42))
  end

  let(:session_data) do
    {
      "omniauth.oidc_sid" => oidc_session_id
    }
  end

  let(:oidc_session_id) { "oidc_sid_foo" }

  before do
    allow(session).to receive(:[]) { |k| session_data[k] }
  end

  describe "handle_login" do
    let!(:plain_session) { create(:user_session, session_id: session.id.private_id) }
    let!(:user_session) { Sessions::UserSession.find_by(session_id: plain_session.session_id) }

    subject { described_class.handle_login session }

    it "creates a user link object" do
      expect { subject }.to change(OpenIDConnect::UserSessionLink, :count).by(1)
      link = OpenIDConnect::UserSessionLink.find_by(session_id: user_session.id)

      expect(link).to be_present
      expect(link.session).to eq user_session
      expect(link.oidc_session).to eq oidc_session_id
    end
  end

  describe "handle_logout" do
    let(:token) { instance_double(OmniAuth::OpenIDConnect::LogoutToken, sid: "oidc_foobar") }

    subject { described_class.handle_logout token }

    context "when an unrelated session exists" do
      let!(:plain_session) { create(:user_session, session_id: "internal_foobar") }
      let!(:user_session) { Sessions::UserSession.find_by(session_id: "internal_foobar") }
      let!(:link) { create(:user_session_link, oidc_session: "other_oidc_sid", session: user_session) }

      it "does not delete it" do
        expect { subject }.not_to change(OpenIDConnect::UserSessionLink, :count)

        expect { link.reload }.not_to raise_error
        expect { user_session.reload }.not_to raise_error
      end
    end

    context "when a linked session exists" do
      let!(:plain_session) { create(:user_session, session_id: "internal_foobar") }
      let!(:user_session) { Sessions::UserSession.find_by(session_id: "internal_foobar") }
      let!(:link) { create(:user_session_link, oidc_session: "oidc_foobar", session: user_session) }

      it "deletes the linked session" do
        expect { subject }.to change(OpenIDConnect::UserSessionLink, :count).by(-1)

        expect { link.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { user_session.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
