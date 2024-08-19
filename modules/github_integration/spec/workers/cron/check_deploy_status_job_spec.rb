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
  let(:pull_request) { create(:github_pull_request, work_packages: [work_package], state: :closed, merge_commit_sha:) }

  let(:job) { described_class.new }

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
