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
require "open_project/api_doc_coverage/endpoint"
require "open_project/api_doc_coverage/differ"
require "open_project/api_doc_coverage/reporter"

RSpec.describe OpenProject::ApiDocCoverage::Reporter do
  def endpoint(method, path, module_name)
    OpenProject::ApiDocCoverage::Endpoint.new(method:, path:, module_name:, params: [])
  end

  def build_diff
    OpenProject::ApiDocCoverage::Differ::Diff.new(
      undocumented_routes: [endpoint("POST", "/api/v3/widgets", "widgets")],
      undocumented_params: [
        { endpoint: endpoint("GET", "/api/v3/widgets/{id}", "widgets"), param_names: ["sortBy"] }
      ],
      orphaned_paths: [endpoint("GET", "/api/v3/gone", "gone")]
    )
  end

  let(:diff) { build_diff }

  it "summarises counts in the JSON hash" do
    summary = described_class.new(diff).to_json_hash["summary"]
    expect(summary).to eq("undocumented_routes" => 1, "undocumented_params" => 1, "orphaned_paths" => 1)
  end

  it "groups the JSON hash by module with stringified endpoints" do
    modules = described_class.new(diff).to_json_hash["modules"]
    expect(modules["widgets"]["undocumented_routes"]).to eq(["POST /api/v3/widgets"])
    expect(modules["widgets"]["undocumented_params"])
      .to eq([{ "endpoint" => "GET /api/v3/widgets/{id}", "params" => ["sortBy"] }])
  end

  it "renders markdown with a heading and the undocumented route" do
    md = described_class.new(diff).to_markdown
    expect(md).to include("# APIv3 documentation coverage")
    expect(md).to include("POST /api/v3/widgets")
  end
end
