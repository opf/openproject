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
require Rails.root.join("modules/repositories/db/migrate/20261015143700_fill_from_gitlab")

RSpec.describe FillFromGitlab, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  let(:base_url) { "https://gitlab.example.com" }
  let(:provider) { Repositories::GitlabProvider.sole }

  let(:wp_one) { create(:work_package) }
  let(:wp_two) { create(:work_package, project: wp_one.project) }
  let(:wp_three) { create(:work_package, project: wp_one.project) }
  let(:gitlab_ids) { (1..).each }

  # The GitLab tables are only written by the code this migration replaces, so the
  # spec builds their rows itself instead of relying on models that no longer exist.
  def gitlab_table(name)
    Class.new(ApplicationRecord) { self.table_name = name }
  end

  def next_gitlab_id = gitlab_ids.next

  def create_gitlab_user(**attributes)
    id = next_gitlab_id
    gitlab_table("gitlab_users").create!(
      { gitlab_id: id, username: "user_#{id}", name: "User #{id}", avatar_url: "#{base_url}/avatar_#{id}.jpg" }
        .merge(attributes)
    )
  end

  def create_gitlab_issue(work_packages: [], **attributes)
    id = next_gitlab_id
    issue = gitlab_table("gitlab_issues").create!(gitlab_resource_defaults(id, "issues").merge(attributes))
    link_work_packages("gitlab_issues_work_packages", gitlab_issue_id: issue.id, work_packages:)
    issue
  end

  def create_gitlab_merge_request(work_packages: [], **attributes)
    id = next_gitlab_id
    merge_request = gitlab_table("gitlab_merge_requests").create!(
      gitlab_resource_defaults(id, "merge_requests").merge(draft: false, merged: false).merge(attributes)
    )
    link_work_packages("gitlab_merge_requests_work_packages", gitlab_merge_request_id: merge_request.id, work_packages:)
    merge_request
  end

  def create_gitlab_pipeline(merge_request:, **attributes)
    id = next_gitlab_id
    gitlab_table("gitlab_pipelines").create!(
      {
        gitlab_merge_request_id: merge_request.id,
        gitlab_id: id,
        name: id.to_s,
        gitlab_html_url: "#{base_url}/group/project/-/pipelines/#{id}",
        project_id: 1,
        gitlab_user_avatar_url: "#{base_url}/avatar.jpg",
        status: "pending",
        started_at: 1.hour.ago
      }.merge(attributes)
    )
  end

  def gitlab_resource_defaults(id, path)
    {
      gitlab_id: id,
      number: id,
      gitlab_html_url: "#{base_url}/group/project/-/#{path}/#{id}",
      state: "opened",
      repository: "Project",
      title: "Title #{id}",
      body: "Body #{id}",
      labels: [],
      gitlab_updated_at: Time.current
    }
  end

  def link_work_packages(table, work_packages:, **resource_key)
    work_packages.each { |work_package| gitlab_table(table).create!(work_package_id: work_package.id, **resource_key) }
  end

  context "without any GitLab data" do
    it "does not create a provider" do
      migrate
      expect(Repositories::Provider.count).to eq(0)
    end
  end

  context "with GitLab data", with_settings: {
    plugin_openproject_gitlab_integration: { gitlab_user_id: "42", webhook_secret: "it's s3cret" }
  } do
    let!(:alice) { create_gitlab_user(username: "alice", name: "Alice Old", updated_at: 2.days.ago) }
    let!(:alice_duplicate) do
      # users may have been created duplicate due to race condition in user creation
      create_gitlab_user(gitlab_id: alice.gitlab_id, username: "alice", name: "Alice New", updated_at: 1.day.ago)
    end

    let!(:issue_in_project_a) do
      create_gitlab_issue(gitlab_user_id: alice.id,
                          gitlab_id: 5,
                          number: 5,
                          gitlab_html_url: "#{base_url}/group/project-a/-/issues/5",
                          work_packages: [wp_one])
    end
    let!(:issue_in_project_b) do
      create_gitlab_issue(gitlab_user_id: alice_duplicate.id,
                          gitlab_id: 5, # due to pre-existing bug gitlab_id equals number always (not unique)
                          number: 5,
                          gitlab_html_url: "#{base_url}/group/project-b/-/issues/5",
                          work_packages: [wp_two])
    end
    let!(:issue_with_nulls) do
      create_gitlab_issue(gitlab_html_url: "#{base_url}/group/project-a/-/issues/6",
                          title: nil, body: nil, labels: nil, gitlab_updated_at: nil)
    end

    let!(:merge_request) do
      create_gitlab_merge_request(gitlab_html_url: "#{base_url}/group/project-a/-/merge_requests/7",
                                  work_packages: [wp_one, wp_three])
    end
    let!(:open_draft_mr) do
      create_gitlab_merge_request(draft: true, gitlab_html_url: "#{base_url}/group/project-a/-/merge_requests/8")
    end
    let!(:merged_draft_mr) do
      create_gitlab_merge_request(draft: true, state: "merged", merged: true, merged_at: Time.current,
                                  gitlab_html_url: "#{base_url}/group/project-a/-/merge_requests/9")
    end
    let!(:mr_without_gitlab_id) do
      create_gitlab_merge_request(gitlab_id: nil, gitlab_html_url: "#{base_url}/group/project-a/-/merge_requests/10")
    end

    let!(:first_pipeline) { create_gitlab_pipeline(merge_request:, username: "alice") }
    let!(:second_pipeline) { create_gitlab_pipeline(merge_request:, username: "alice") }

    it "creates a single provider with the base URL and the plugin settings" do
      migrate
      expect(provider).to have_attributes(
        name: "GitLab",
        url: base_url,
        gitlab_user_id: 42,
        webhook_secret: "it's s3cret"
      )
    end

    it "copies duplicated GitLab users only once, keeping the most recently updated one" do
      migrate
      expect(Repositories::User.where(external_id: alice.gitlab_id.to_s).sole).to have_attributes(name: "Alice New", provider:)
    end

    it "keeps issues with the same iid in different projects apart" do
      migrate
      issue_a = Repositories::Issue.find_by!(web_url: issue_in_project_a.gitlab_html_url)
      issue_b = Repositories::Issue.find_by!(web_url: issue_in_project_b.gitlab_html_url)

      expect(issue_a.work_package_ids).to contain_exactly(wp_one.id)
      expect(issue_b.work_package_ids).to contain_exactly(wp_two.id)
    end

    it "attributes issues of duplicated users to the single migrated user" do
      migrate
      user = Repositories::User.find_by!(external_id: alice.gitlab_id.to_s)

      expect(Repositories::Issue.where(repository_user: user).pluck(:web_url))
        .to contain_exactly(issue_in_project_a.gitlab_html_url, issue_in_project_b.gitlab_html_url)
    end

    it "fills NULL columns with defaults instead of dropping the issue" do
      migrate
      expect(Repositories::Issue.find_by!(web_url: issue_with_nulls.gitlab_html_url)).to have_attributes(
        title: "",
        description: "",
        labels: [],
        external_updated_at: issue_with_nulls.reload.updated_at
      )
    end

    it "carries over the work package links of merge requests" do
      migrate
      mr = Repositories::MergeRequest.find_by!(web_url: merge_request.gitlab_html_url)

      expect(mr.work_package_ids).to contain_exactly(wp_one.id, wp_three.id)
    end

    it "migrates each pipeline exactly once and attributes it to the deduplicated user" do
      migrate
      mr = Repositories::MergeRequest.find_by!(web_url: merge_request.gitlab_html_url)
      user = Repositories::User.find_by!(external_id: alice.gitlab_id.to_s)

      expect(Repositories::Pipeline.where(merge_request: mr).pluck(:external_id, :repository_user_id))
        .to contain_exactly([first_pipeline.gitlab_id, user.id], [second_pipeline.gitlab_id, user.id])
    end

    it "maps open draft merge requests to the draft state" do
      migrate
      expect(Repositories::MergeRequest.find_by!(web_url: open_draft_mr.gitlab_html_url).state).to eq("draft")
    end

    it "keeps the state of merge requests that are no longer open" do
      migrate
      expect(Repositories::MergeRequest.find_by!(web_url: merged_draft_mr.gitlab_html_url).state).to eq("merged")
    end

    it "skips merge requests without a GitLab id" do
      migrate
      expect(Repositories::MergeRequest.find_by(web_url: mr_without_gitlab_id.gitlab_html_url)).to be_nil
    end
  end
end
