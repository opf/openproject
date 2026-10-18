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
require "tmpdir"
require "open_project/api_doc_coverage/ledger"
require "open_project/api_doc_coverage/wp_filer"

RSpec.describe OpenProject::ApiDocCoverage::WpFiler do
  let(:dir) { Dir.mktmpdir }
  let(:ledger) { OpenProject::ApiDocCoverage::Ledger.new(File.join(dir, "wps.yml")) }
  let(:report) do
    {
      "modules" => {
        "widgets" => { "undocumented_routes" => ["POST /api/v3/widgets"], "undocumented_params" => [], "orphaned_paths" => [] },
        "gone" => { "undocumented_routes" => [], "undocumented_params" => [], "orphaned_paths" => ["GET /api/v3/gone"] }
      }
    }
  end

  after { FileUtils.remove_entry(dir) }

  it "creates a WP with a positional subject and target project, recording the id from JSON" do
    calls = []
    runner = lambda do |args|
      calls << args
      { "id" => 4242 }.to_json
    end
    filer = described_class.new(report_hash: report, ledger:, project: "my_project", runner:)
    result = filer.file(modules: ["widgets"])

    expect(calls.first).to include("work-package", "create", "--project", "my_project")
    expect(calls.first).not_to include("--subject")
    expect(result).to contain_exactly(hash_including(module: "widgets", wp_id: "4242", action: :created))
    expect(ledger.id_for("widgets")).to eq("4242")
  end

  it "updates the existing WP when the ledger already has an id" do
    ledger.record("widgets", "999")
    calls = []
    runner = lambda do |args|
      calls << args
      ""
    end
    filer = described_class.new(report_hash: report, ledger:, project: "my_project", runner:)
    result = filer.file(modules: ["widgets"])

    expect(calls.first).to include("work-package", "update", "999")
    expect(result).to contain_exactly(hash_including(module: "widgets", wp_id: "999", action: :updated))
  end

  it "skips modules with only advisory/info findings" do
    runner = ->(_args) { raise "should not be called" }
    filer = described_class.new(report_hash: report, ledger:, project: "my_project", runner:)
    expect(filer.file(modules: ["gone"])).to eq([])
  end
end
