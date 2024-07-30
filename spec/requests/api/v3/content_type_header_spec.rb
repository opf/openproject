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
require "rack/test"

RSpec.describe "API v3 Content-Type header" do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  shared_let(:project)      { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_current_user       { create(:admin) }

  before do
    allow(current_session).to receive(:env_for).and_wrap_original do |original_method, *args, &block|
      original_method.call(*args, &block).except("CONTENT_TYPE")
    end
  end

  describe "a missing Content-Type header" do
    context "on a GET request" do
      it "is successful" do
        get api_v3_paths.work_package(work_package.id)
        expect(last_response.status).not_to have_http_status(:not_acceptable)
        expect(last_response).to be_ok
      end
    end

    context "on a DELETE request" do
      it "is successful" do
        delete api_v3_paths.work_package(work_package.id)
        expect(last_response.status).not_to have_http_status(:not_acceptable)
        expect(last_response).to be_no_content
      end
    end

    context "on any other HTTP method" do
      it "responds with a 406 status and a missing Content-Type header message" do
        patch api_v3_paths.work_package(work_package.id), {}
        expect(last_response).to have_http_status(:not_acceptable)
        expect(last_response.body).to include("Missing content-type header")
      end
    end
  end
end
