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

require "open_project/api_doc_coverage/route_extractor"
require "open_project/api_doc_coverage/spec_extractor"
require "open_project/api_doc_coverage/ignore_list"
require "open_project/api_doc_coverage/differ"
require "open_project/api_doc_coverage/reporter"

namespace :api do
  namespace :docs do
    desc "Report APIv3 routes/params served by code but missing from the OpenAPI spec"
    task coverage: [:environment] do
      mod = OpenProject::ApiDocCoverage
      spec_path = Rails.root.join("docs/api/apiv3/openapi-spec.yml")
      ignore = mod::IgnoreList.from_file(Rails.root.join("docs/api/apiv3/.coverage-ignore.yml").to_s)

      routes = ignore.reject(mod::RouteExtractor.new.endpoints)
      specs = mod::SpecExtractor.new(API::OpenAPI.assemble_spec(spec_path)).endpoints
      diff = mod::Differ.new(routes:, specs:).diff
      reporter = mod::Reporter.new(diff)

      md_path = Rails.root.join("tmp/api-doc-coverage.md")
      json_path = Rails.root.join("tmp/api-doc-coverage.json")
      File.write(md_path, reporter.to_markdown)
      File.write(json_path, JSON.pretty_generate(reporter.to_json_hash))

      s = reporter.to_json_hash["summary"]
      puts "API doc coverage: #{s['undocumented_routes']} undocumented routes, " \
           "#{s['undocumented_params']} endpoints with undocumented params, " \
           "#{s['orphaned_paths']} orphaned doc paths."
      puts "Report: #{md_path}"
    end
  end
end
