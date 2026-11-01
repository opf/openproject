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
require "open_project/api_doc_coverage/ignore_list"

RSpec.describe OpenProject::ApiDocCoverage::IgnoreList do
  def endpoint(method, path)
    OpenProject::ApiDocCoverage::Endpoint.new(method:, path:, module_name: "x", params: [])
  end

  it "rejects endpoints matching a 'METHOD path' entry" do
    list = described_class.new(["GET /api/v3/secret"])
    kept = list.reject([endpoint("GET", "/api/v3/secret"), endpoint("GET", "/api/v3/public")])
    expect(kept.map(&:path)).to eq(["/api/v3/public"])
  end

  it "treats a missing file as an empty list" do
    list = described_class.from_file("/nonexistent/does-not-exist.yml")
    ep = endpoint("GET", "/api/v3/anything")
    expect(list.reject([ep])).to eq([ep])
  end
end
