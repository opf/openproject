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

RSpec.describe OpenProject::ApiDocCoverage::Differ do
  include OpenProject::ApiDocCoverage

  def ep(method, path, params = [])
    OpenProject::ApiDocCoverage::Endpoint.new(
      method:, path:,
      module_name: path.delete_prefix("/api/v3/").split("/").first,
      params:
    )
  end

  def param(name, location: nil, required: false)
    OpenProject::ApiDocCoverage::Param.new(name:, location:, required:)
  end

  it "flags routes present in code but missing from the spec" do
    routes = [ep("GET", "/api/v3/widgets"), ep("POST", "/api/v3/widgets")]
    specs  = [ep("GET", "/api/v3/widgets")]
    diff = described_class.new(routes:, specs:).diff
    expect(diff.undocumented_routes.map { |e| [e.method, e.path] }).to eq([["POST", "/api/v3/widgets"]])
  end

  it "flags params in code but missing from the spec, excluding path params" do
    routes = [ep("GET", "/api/v3/widgets/{id}",
                 [param("id", location: "path"), param("filter"), param("sortBy")])]
    specs  = [ep("GET", "/api/v3/widgets/{id}",
                 [param("id", location: "path"), param("filter", location: "query")])]
    diff = described_class.new(routes:, specs:).diff
    expect(diff.undocumented_params).to contain_exactly(
      hash_including(param_names: ["sortBy"])
    )
  end

  it "flags spec paths with no matching route as orphaned" do
    routes = [ep("GET", "/api/v3/widgets")]
    specs  = [ep("GET", "/api/v3/widgets"), ep("GET", "/api/v3/gone")]
    diff = described_class.new(routes:, specs:).diff
    expect(diff.orphaned_paths.map(&:path)).to eq(["/api/v3/gone"])
  end

  it "groups results by module" do
    routes = [ep("POST", "/api/v3/widgets"), ep("POST", "/api/v3/gadgets")]
    specs  = []
    by_module = described_class.new(routes:, specs:).diff.by_module
    expect(by_module.keys).to contain_exactly("widgets", "gadgets")
    expect(by_module["widgets"][:undocumented_routes].size).to eq(1)
  end
end
