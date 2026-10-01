# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe ApplicationController, "session lifetime handling" do # rubocop:disable RSpec/SpecFilePathFormat
  shared_let(:user) { create(:user) }

  controller do
    authorization_checked! :index

    def index
      render plain: "OK"
    end
  end

  before do
    @routes.draw { get "/anonymous/index" } # rubocop:disable RSpec/InstanceVariable
    session[:user_id] = user.id
  end

  after { User.current = nil }

  context "when the session TTL is enabled", with_settings: { session_ttl_enabled?: true, session_ttl: "120" } do
    context "and the last activity is within the refresh interval" do
      it "does not rewrite the session timestamp, avoiding a redundant session write" do
        last_seen = 1.minute.ago
        session[:updated_at] = last_seen

        get :index

        expect(response).to have_http_status(:ok)
        expect(session[:updated_at]).to eq(last_seen)
      end
    end

    context "and the last activity is older than the refresh interval but within the TTL" do
      it "refreshes the session timestamp" do
        session[:updated_at] = 10.minutes.ago

        get :index

        expect(response).to have_http_status(:ok)
        expect(session[:updated_at]).to be_within(5.seconds).of(Time.current)
      end
    end

    context "and the last activity exceeds the TTL" do
      it "logs the user out and does not refresh the now-invalidated session" do
        # The anonymous controller has no generatable route for the back_url
        allow(controller).to receive(:login_back_url).and_return("/")
        allow(controller).to receive(:refresh_session_activity)
        session[:updated_at] = 3.hours.ago

        get :index

        expect(controller).not_to have_received(:refresh_session_activity)
        expect(response).to have_http_status(:redirect)
        expect(flash[:warning]).to eq(I18n.t(:notice_forced_logout, ttl_time: Setting.session_ttl))
      end
    end
  end

  context "with a short TTL", with_settings: { session_ttl_enabled?: true, session_ttl: "5" } do
    it "refreshes more promptly, scaling the interval down with the TTL" do
      # 90s is past the ~1 minute interval a 5 minute TTL yields, but would have
      # been skipped by a fixed multi-minute window.
      session[:updated_at] = 90.seconds.ago

      get :index

      expect(response).to have_http_status(:ok)
      expect(session[:updated_at]).to be_within(5.seconds).of(Time.current)
    end
  end

  context "when the session TTL is disabled", with_settings: { session_ttl_enabled?: false } do
    it "does not terminate even a very old session" do
      session[:updated_at] = 1.year.ago

      get :index

      expect(response).to have_http_status(:ok)
      expect(session[:user_id]).to eq(user.id)
    end

    it "still refreshes a stale timestamp for the 30-day cleanup window" do
      session[:updated_at] = 10.minutes.ago

      get :index

      expect(session[:updated_at]).to be_within(5.seconds).of(Time.current)
    end

    it "does not rewrite a fresh timestamp" do
      last_seen = 30.seconds.ago
      session[:updated_at] = last_seen

      get :index

      expect(session[:updated_at]).to eq(last_seen)
    end
  end
end
