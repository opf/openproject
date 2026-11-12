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

RSpec.describe "OAuth 2.0 Protected Resource Metadata", content_type: :json do
  let(:expected_schema) do
    {
      required: %w[resource resource_name authorization_servers scopes_supported bearer_methods_supported resource_documentation],
      properties: {
        resource: { type: "string" },
        resource_name: { type: "string" },
        authorization_servers: { type: "array", items: { type: "string" } },
        scopes_supported: { type: "array", items: { type: "string" } },
        bearer_methods_supported: { type: "array", items: { type: "string" } },
        resource_documentation: { type: "string" }
      }
    }
  end

  it "is successful" do
    get "/.well-known/oauth-protected-resource"
    expect(last_response).to have_http_status(200)
  end

  it "has the expected structure" do
    get "/.well-known/oauth-protected-resource"
    expect(last_response.body).to match_json_schema(expected_schema)
  end
end
