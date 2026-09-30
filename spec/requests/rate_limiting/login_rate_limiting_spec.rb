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

# Use a small burst_limit (3) so tests stay fast, and a large burst_period so
# the time-bucketed cache key never rolls over mid-test on a slow CI machine.
RSpec.describe "Rate limiting login",
               :with_rack_attack,
               with_config: { rate_limiting: { login: { burst_limit: 3, burst_period: 3600 } } },
               type: :rails_request do
  before do
    allow_any_instance_of(ActionController::Base) # rubocop:disable RSpec/AnyInstance
      .to(receive(:protect_against_forgery?))
      .and_return(false)
  end

  it "blocks after burst_limit attempts for the same username" do
    freeze_time do
      3.times do
        post signin_path, params: { username: "victim", password: "wrong" }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      post signin_path, params: { username: "victim", password: "wrong" }
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include "Too many login attempts"
    end
  end

  it "does not affect a different username" do
    freeze_time do
      3.times { post signin_path, params: { username: "victim", password: "wrong" } }

      post signin_path, params: { username: "other_user", password: "wrong" }
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  it "is case-insensitive on the username" do
    freeze_time do
      2.times { post signin_path, params: { username: "Victim", password: "wrong" } }
      post signin_path, params: { username: "VICTIM", password: "wrong" }

      post signin_path, params: { username: "victim", password: "wrong" }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  it "does not throttle when no username is submitted" do
    4.times { post signin_path, params: {} }
    expect(response).not_to have_http_status(:too_many_requests)
  end

  context "when disabled", with_config: { rate_limiting: { login: false } } do
    before { OpenProject::RateLimiting.set_defaults! }

    it "does not block repeated login attempts" do
      4.times do
        post signin_path, params: { username: "victim", password: "wrong" }
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end
end
