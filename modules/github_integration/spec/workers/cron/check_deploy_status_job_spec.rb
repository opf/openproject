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

RSpec.describe Cron::CheckDeployStatusJob, type: :job, with_flag: { deploy_targets: true } do
  let(:api_key) { "foobar42" }

  let(:merge_commit_sha) { "576e25f7befffa5fc02a4311704e9894a5c9bdd4" }
  let(:core_sha) { "663f3a128aef9c0b031cbd59bb6f740ee50130a7" }

  let(:work_package) { create(:work_package) }

  let(:deploy_target) { create(:deploy_target, api_key:) }
  let(:pull_request) do
    create :github_pull_request, pull_request_attributes.merge(pull_request_attribute_override)
  end

  let(:pull_request_attributes) do
    {
      work_packages: [work_package],
      state: :closed,
      repository: "opf/openproject",
      merge_commit_sha:,
      merged: true,
      merged_at: Date.yesterday
    }
  end

  let(:pull_request_attribute_override) { {} }

  let(:job) { described_class.new }

  describe "#pull_requests" do
    before do
      pull_request
    end

    context "with matching PRs" do
      it "includes them" do
        expect(job.pull_requests).to include pull_request
      end
    end

    context "with not merged PRs" do
      let(:pull_request_attribute_override) { { merged: false } }

      it "does not include them" do
        expect(job.pull_requests).not_to include pull_request
      end
    end

    context "with PRs from other repositories" do
      let(:pull_request_attribute_override) { { repository: "opf/website" } }

      it "does not include them" do
        expect(job.pull_requests).not_to include pull_request
      end
    end

    context "with PRs past the use-by date" do
      let(:pull_request_attribute_override) { { merged_at: Date.today - 2.months } }

      it "does not include them" do
        expect(job.pull_requests).not_to include pull_request
      end
    end
  end

  describe "#commit_contains?", :webmock do
    let(:result) { job.commit_contains? core_sha, merge_commit_sha }
    let(:response) { {} }

    let(:request_url) { "https://api.github.com/repos/opf/openproject/compare/#{core_sha}...#{merge_commit_sha}" }
    let(:request_headers) do
      {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip, deflate",
        "User-Agent" => "httpx.rb/1.3.1"
      }
    end

    before do
      stub_request(:get, request_url)
        .with(headers: request_headers)
        .to_return(status: 200, body: response.to_json, headers: {})
    end

    context "with a response not indicating the commits are related" do
      it "is false" do
        expect(result).to eq false
      end
    end

    context "with a response indicating the commits are related" do
      let(:response) do
        {
          status: "behind",
          ahead_by: 0,
          behind_by: 42
        }
      end

      it "is true" do
        expect(result).to eq true
      end
    end

    context(
      "with a github access token configured",
      with_settings: {
        plugin_openproject_github_integration: {
          github_access_token: "pat_42"
        }
      }
    ) do
      it "sends an authenticated request" do
        result

        expect(WebMock)
          .to have_requested(:get, request_url)
          .with(headers: { "Authorization" => "Bearer pat_42" })
      end
    end

    context "with an invalid access token" do
      before do
        stub_request(:get, request_url)
          .with(headers: request_headers)
          .to_return(status: 401, body: response.to_json, headers: { message: "invalid token" })
      end

      it "raises an error" do
        expect { result }.to raise_error(Cron::CheckDeployStatusJob::DeployCheckAccessTokenExpired)
      end
    end
  end

  context "with no prior checks and the same deployed sha" do
    before do
      deploy_target
      pull_request

      allow(job).to receive(:openproject_core_sha).with(deploy_target.host, api_key).and_return(core_sha)
      allow(job).to receive(:commit_contains?).with(core_sha, merge_commit_sha).and_return true

      job.perform
    end

    it "marks the pull request 'deployed'" do
      expect(pull_request.reload.state).to eq "deployed"
    end
  end

  context "with prior checks" do
    before do
      allow(job).to receive(:openproject_core_sha).with(deploy_target.host, api_key).and_return(core_sha)
      allow(job).to receive :commit_contains?
    end

    context "with the same core sha" do
      let!(:deploy_status_check) { create(:deploy_status_check, deploy_target:, github_pull_request: pull_request, core_sha:) }

      before do
        job.perform
      end

      it "leaves the pull request closed while not checking with github again" do
        expect(pull_request.reload.state).to eq "closed"
        expect(job).not_to have_received :commit_contains?
      end
    end

    context "with a different core sha in the previous check" do
      let!(:deploy_status_check) do
        create(:deploy_status_check, deploy_target:, github_pull_request: pull_request, core_sha: "foo")
      end

      before do
        allow(job).to receive(:commit_contains?).with(core_sha, merge_commit_sha).and_return contains_commit

        job.perform
      end

      context "with the same core sha deployed" do
        let(:contains_commit) { true }

        it "marks the pull request deployed" do
          expect(pull_request.reload.state).to eq "deployed"
        end

        it "has checked with github again" do
          expect(job).to have_received(:commit_contains?).with(core_sha, merge_commit_sha)
        end
      end

      context "with a different core sha deployed" do
        let(:contains_commit) { false }

        it "leaves the pull request closed" do
          expect(pull_request.reload.state).to eq "closed"
        end

        it "has checked with github again" do
          expect(job).to have_received(:commit_contains?).with(core_sha, merge_commit_sha)
        end
      end
    end
  end
end
