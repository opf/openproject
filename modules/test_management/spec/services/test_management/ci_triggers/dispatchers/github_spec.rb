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

RSpec.describe TestManagement::CiTriggers::Dispatchers::Github, :disable_ssrf_filter, :webmock do
  let(:connection) { build_stubbed(:tm_ci_connection, :github_trigger, trigger_ref: "release") }
  let(:url) { "https://api.github.com/repos/my-org/shop/actions/workflows/e2e.yml/dispatches" }
  let(:inputs) { { op_run_id: 5, op_iteration_id: 6, op_project: "shop", op_grep: "adds" } }

  def dispatch(ref: "release")
    described_class.new(connection:).call(ref:, inputs:)
  end

  it "dispatches the workflow with the ref and string inputs and the bearer token" do
    stub = stub_request(:post, url)
             .with(headers: { "Authorization" => "Bearer ghp_trigger_secret" },
                   body: { ref: "release",
                           inputs: { op_run_id: "5", op_iteration_id: "6", op_project: "shop", op_grep: "adds" },
                           return_run_details: true })
             .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                        body: { workflow_run_id: 42, html_url: "https://github.com/my-org/shop/actions/runs/42" }.to_json)

    result = dispatch

    expect(stub).to have_been_requested
    expect(result).to have_attributes(status: "triggered", external_id: "42",
                                      url: "https://github.com/my-org/shop/actions/runs/42")
  end

  it "links the workflow page when GitHub answers 204" do
    stub_request(:post, url).to_return(status: 204)

    expect(dispatch).to have_attributes(status: "triggered", url: "https://github.com/my-org/shop/actions/workflows/e2e.yml")
  end

  it "fails with a scrubbed error on 422" do
    stub_request(:post, url).to_return(status: 422, headers: { "Content-Type" => "application/json" },
                                       body: { message: "bad input ghp_trigger_secret" }.to_json)

    result = dispatch

    expect(result.status).to eq("failed")
    expect(result.error).to eq("HTTP 422: bad input [FILTERED]")
  end

  it "reports network errors as failures" do
    stub_request(:post, url).to_timeout

    expect(dispatch.status).to eq("failed")
  end
end
