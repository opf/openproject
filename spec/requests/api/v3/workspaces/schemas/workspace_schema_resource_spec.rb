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
require "rack/test"

RSpec.describe "API v3 Workspaces schema resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:user) do
    create(:user)
  end

  current_user { user }

  subject(:response) { last_response }

  shared_examples_for "fetching the workspace schema" do
    before do
      get path
    end

    it "responds with 200 OK" do
      expect(subject.status).to eq(200)
    end

    it "returns a schema" do
      expect(subject.body)
        .to be_json_eql("Schema".to_json)
        .at_path "_type"
    end

    it "does not embed" do
      expect(subject.body)
        .not_to have_json_path("parent/_links/allowedValues")
    end

    it "has the workspace route as its self link" do
      expect(subject.body)
        .to be_json_eql(api_v3_paths.workspace_schema.to_json)
              .at_path "_links/self/href"
    end
  end

  describe "GET /projects/schema" do
    include_examples "fetching the workspace schema" do
      let(:path) { api_v3_paths.project_schema }
    end
  end

  describe "GET /workspaces/schema" do
    include_examples "fetching the workspace schema" do
      let(:path) { api_v3_paths.workspace_schema }
    end
  end
end
