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

require "rails_helper"
require "open_project/api_doc_coverage/route_extractor"

RSpec.describe OpenProject::ApiDocCoverage::RouteExtractor do
  subject(:endpoints) { described_class.new.endpoints }

  it "returns Endpoints with canonical /api/v3 paths and no format suffix" do
    expect(endpoints).to all(have_attributes(path: start_with("/api/v3")))
    expect(endpoints.map(&:path)).to all(satisfy { |p| p.exclude?(".:format") && p.exclude?(":") })
  end

  it "finds the work_packages collection GET" do
    wp_get = endpoints.find { |e| e.method == "GET" && e.path == "/api/v3/work_packages" }
    expect(wp_get).not_to be_nil
    expect(wp_get.module_name).to eq("work_packages")
  end

  it "never emits the noise params format or version" do
    names = endpoints.flat_map { |e| e.params.map(&:name) }
    expect(names).not_to include("format", "version")
  end

  it "marks id in a member route as a path param" do
    wp_member = endpoints.find { |e| e.method == "GET" && e.path == "/api/v3/work_packages/{id}" }
    expect(wp_member.params.find { |p| p.name == "id" }).to have_attributes(location: "path")
  end

  it "converts splat params to {param} rather than leaking a '*'" do
    expect(endpoints.map(&:path)).to all(satisfy { |p| p.exclude?("*") })
  end

  it "excludes the Grape catch-all route with the wildcard '*' method" do
    expect(endpoints.map(&:method).uniq).to all(satisfy { |m| described_class::HTTP_METHODS.include?(m) })
  end
end
