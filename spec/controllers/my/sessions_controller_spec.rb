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

RSpec.describe My::SessionsController do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe "#index" do
    let!(:autologin_token) do
      create(:autologin_token, user:, expires_on: 1.year.from_now)
    end

    let!(:expired_autologin_token) do
      create(:autologin_token, user:, expires_on: 1.year.ago)
    end

    let!(:auto_login_token_in_cookie) do
      create(:autologin_token, user:, expires_on: 1.year.from_now)
    end

    let!(:auto_login_token_other_user) do
      create(:autologin_token, expires_on: 1.year.from_now)
    end

    let!(:unmapped_session) do
      # As session models are readonly we need to create them with the factory and then manually refind them
      session = create(:user_session, user:)
      Sessions::UserSession.find_by(session_id: session.session_id)
    end

    before do
      cookies[OpenProject::Configuration["autologin_cookie_name"]] = auto_login_token_in_cookie.plain_value
    end

    it "assigns all variables the views expect" do
      get :index

      expect(assigns(:autologin_tokens)).to contain_exactly(autologin_token, auto_login_token_in_cookie)
      expect(assigns(:unmapped_sessions)).to contain_exactly(unmapped_session)
      expect(assigns(:current_token)).to eq(auto_login_token_in_cookie)
    end

    context "when no autologin token is in the cookie" do
      before do
        cookies.delete(OpenProject::Configuration["autologin_cookie_name"])
      end

      it "does not assign a current_token" do
        get :index

        expect(assigns(:current_token)).to be_nil
      end
    end
  end

  describe "#destroy" do
    let(:session_owner) { user }
    let!(:session) do
      # As session models are readonly we need to create them with the factory and then manually refind them
      session = create(:user_session, user: session_owner)
      Sessions::UserSession.find_by(session_id: session.session_id)
    end

    let(:is_current_session) { false }

    before do
      # We do not want to mock any loading of the session itself as that is also a security relevant path.
      allow_any_instance_of(Sessions::UserSession) # rubocop:disable RSpec/AnyInstance
        .to receive(:current?)
        .and_return(is_current_session)
    end

    context "when session is current session" do
      let(:is_current_session) { true }

      it "prevents deletion of the current session" do
        delete :destroy, params: { id: session.id }

        expect { session.reload }.not_to raise_error

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when session is not current session" do
      let(:is_current_session) { false }

      it "allows deletion of other sessions" do
        delete :destroy, params: { id: session.id }

        expect { session.reload }.to raise_error(ActiveRecord::RecordNotFound)

        expect(response).to redirect_to(my_sessions_path)
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_delete))
      end
    end

    context "when the session belongs to another user" do
      let(:session_owner) { create(:user) }

      it "responds with 404 Not Found" do
        delete :destroy, params: { id: session.id }

        expect { session.reload }.not_to raise_error

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
