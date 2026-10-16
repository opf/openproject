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

RSpec.describe OpenProject::Authentication::WWWAuthenticate do
  describe ".response_header" do
    let(:env) { Rack::MockRequest.env_for("http://test.host/api/v3/projects") }
    let(:resource_metadata) { 'resource_metadata="http://test.host/.well-known/oauth-protected-resource"' }

    it "uses the Warden scope as the scope attribute" do
      expect(described_class.response_header(env:, scope: :api_v3, error: "insufficient_scope"))
        .to eq(%{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3", error="insufficient_scope"})
    end

    it "lists the given OAuth scopes space-separated as the scope attribute" do
      header = described_class.response_header(env:,
                                               scope: :api_v3,
                                               oauth_scopes: %w[api_v3 edit_documents],
                                               error: "insufficient_scope")

      expect(header).to eq(
        %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3 edit_documents", error="insufficient_scope"}
      )
    end
  end
end
