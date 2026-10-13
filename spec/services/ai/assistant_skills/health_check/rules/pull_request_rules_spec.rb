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
require_relative "../shared_context"

RSpec.describe "health check pull request rules" do # rubocop:disable RSpec/DescribeClass
  include_context "with a health check context"

  shared_let(:default_status) { create(:default_status) }
  shared_let(:github_project) { create(:project, enabled_module_names: %w[work_package_tracking github gitlab]) }
  shared_let(:github_user) do
    create(:user, member_with_permissions: {
             github_project => %i[view_work_packages show_github_content show_gitlab_content]
           })
  end

  let(:project) { github_project }
  let(:user) { github_user }
  let(:merged) { AI::AssistantSkills::HealthCheck::Rules::MergedPullRequestDefaultStatus.call(context) }
  let(:closed_open) { AI::AssistantSkills::HealthCheck::Rules::ClosedWithOpenPullRequest.call(context) }

  context "with a merged GitHub pull request and the default status" do
    let(:work_package_status) { default_status }

    before { work_package.github_pull_requests << create(:github_pull_request, state: "closed", merged: true) }

    it "reports a high finding with a link to the pull request" do
      expect(merged.size).to eq(1)
      expect(merged.first).to include(severity: "high", area: "pull_requests")
      expect(merged.first[:evidence].first["url"]).to start_with("https://github.com/")
    end
  end

  context "with a merged GitLab merge request and the default status" do
    let(:work_package_status) { default_status }

    before { work_package.gitlab_merge_requests << create(:gitlab_merge_request, :closed_merged) }

    it "reports a high finding" do
      expect(merged.size).to eq(1)
    end
  end

  context "when closed with an open pull request" do
    let(:work_package_status) { closed_status }

    before do
      work_package.github_pull_requests << create(:github_pull_request, state: "open")
      work_package.github_pull_requests << create(:github_pull_request, state: "open", draft: true)
    end

    it "reports one medium finding for the pull request that is not a draft" do
      expect(closed_open.size).to eq(1)
      expect(closed_open.first[:evidence].size).to eq(1)
    end
  end

  context "when the user may not see GitHub content" do
    let(:user) { create(:user, member_with_permissions: { github_project => %i[view_work_packages show_gitlab_content] }) }
    let(:work_package_status) { default_status }

    before { work_package.github_pull_requests << create(:github_pull_request, state: "closed", merged: true) }

    it "reports nothing and lists GitHub as not checked" do
      expect(merged).to be_empty
      expect(context.not_checked).to include("area" => "pull_requests", "reason" => "no_permission_github")
    end
  end

  context "when the project does not use the integrations" do
    let(:project) { create(:project, enabled_module_names: %w[work_package_tracking]) }
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "reports nothing and lists nothing as not checked" do
      expect(merged).to be_empty
      expect(context.not_checked).to be_empty
    end
  end
end
