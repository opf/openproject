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
require "open_project/api_doc_coverage/spec_extractor"

RSpec.describe OpenProject::ApiDocCoverage::SpecExtractor do
  subject(:endpoints) { described_class.new(spec).endpoints }

  let(:spec) do
    {
      "paths" => {
        "/api/v3/work_packages" => {
          "get" => { "parameters" => [{ "name" => "pageSize", "in" => "query", "required" => false }] },
          "post" => {
            "requestBody" => {
              "content" => {
                "application/json" => { "schema" => { "$ref" => "#/components/schemas/wp_write" } }
              }
            }
          }
        },
        "/api/v3/work_packages/{id}" => {
          "get" => { "parameters" => [{ "name" => "id", "in" => "path", "required" => true }] }
        }
      },
      "components" => {
        "schemas" => {
          "wp_write" => { "required" => ["subject"], "properties" => { "subject" => {}, "description" => {} } }
        }
      }
    }
  end

  it "emits one endpoint per path+method with uppercased methods" do
    expect(endpoints.map { |e| [e.method, e.path] }).to contain_exactly(
      ["GET", "/api/v3/work_packages"],
      ["POST", "/api/v3/work_packages"],
      ["GET", "/api/v3/work_packages/{id}"]
    )
  end

  it "extracts parameters with their location" do
    get_collection = endpoints.find { |e| e.method == "GET" && e.path == "/api/v3/work_packages" }
    expect(get_collection.params).to contain_exactly(
      have_attributes(name: "pageSize", location: "query", required: false)
    )
  end

  it "extracts requestBody properties as body params, honouring required" do
    post = endpoints.find { |e| e.method == "POST" }
    expect(post.params).to contain_exactly(
      have_attributes(name: "subject", location: "body", required: true),
      have_attributes(name: "description", location: "body", required: false)
    )
  end

  it "sets the module name from the path" do
    expect(endpoints.map(&:module_name).uniq).to eq(["work_packages"])
  end
end
