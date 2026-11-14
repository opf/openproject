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

RSpec.describe "api:docs:file_wps", type: :task do
  let(:json_path) { Rails.root.join("tmp/api-doc-coverage.json") }
  let(:report) do
    {
      "modules" => {
        "widgets" => { "undocumented_routes" => ["POST /api/v3/widgets"], "undocumented_params" => [], "orphaned_paths" => [] }
      }
    }
  end

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("api:docs:file_wps")
    json_path.write(report.to_json)
    ENV["OP_API_DOC_COVERAGE_PROJECT"] = "test_project"
  end

  after do
    Rake::Task["api:docs:file_wps"].reenable
    ENV.delete("OP_API_DOC_COVERAGE_PROJECT")
  end

  it "invokes the filer for the requested module, passing the target project" do
    fake = instance_double(OpenProject::ApiDocCoverage::WpFiler,
                           file: [{ module: "widgets", wp_id: "1", action: :created }])
    allow(OpenProject::ApiDocCoverage::WpFiler).to receive(:new).and_return(fake)
    expect { Rake::Task["api:docs:file_wps"].invoke("widgets") }.not_to raise_error
    expect(OpenProject::ApiDocCoverage::WpFiler)
      .to have_received(:new).with(hash_including(project: "test_project"))
    expect(fake).to have_received(:file).with(modules: ["widgets"])
  end
end
