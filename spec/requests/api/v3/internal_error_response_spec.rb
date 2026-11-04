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

RSpec.describe "API v3 internal error response", content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  let(:exception_message) { "could not obtain a connection from the pool at db.internal.example:5432" }

  before do
    login_as admin
    allow(Status).to receive(:visible).and_raise(ActiveRecord::ConnectionTimeoutError, exception_message)
  end

  subject(:response) do
    get api_v3_paths.statuses
    last_response
  end

  it "responds with the generic message only", :aggregate_failures do
    expect(response).to have_http_status(:internal_server_error)
    expect(response.body)
      .to be_json_eql("urn:openproject-org:api:v3:errors:InternalServerError".to_json)
      .at_path("errorIdentifier")
    expect(response.body).to be_json_eql(I18n.t("api_v3.errors.code_500").to_json).at_path("message")
    expect(response.body).not_to include("db.internal.example")
  end
end
