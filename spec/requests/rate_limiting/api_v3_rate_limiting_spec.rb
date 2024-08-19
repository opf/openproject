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

RSpec.describe "Rate limiting APIv3",
               :with_rack_attack do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  current_user { create(:admin) }

  context "when enabled", with_config: { rate_limiting: { api_v3: true } } do
    it "blocks post request to any form" do
      # Need to reload rules again after config change
      OpenProject::RateLimiting.set_defaults!

      # First requests sets the cookie discriminator
      get "/"

      6.times do
        post "/api/v3/work_packages/form",
             nil,
             "CONTENT_TYPE" => "application/json"

        expect(last_response).to have_http_status :ok
      end

      post "/api/v3/work_packages/form",
           nil,
           "CONTENT_TYPE" => "application/json"
      expect(last_response).to have_http_status :too_many_requests
    end
  end

  context "when disabled", with_config: { rate_limiting: { api_v3: false } } do
    it "does not block post request to any form" do
      # Need to reload rules again after config change
      OpenProject::RateLimiting.set_defaults!

      9.times do
        post "/api/v3/work_packages/form",
             nil,
             "CONTENT_TYPE" => "application/json"

        expect(last_response).to have_http_status :ok
      end
    end
  end
end
