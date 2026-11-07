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

RSpec.describe "Work Package Activity Tab",
               "Comments by Gitlab",
               :js do
  shared_let(:gitlab_system_user) { create(:admin, firstname: "Gitlab", lastname: "System User") }
  shared_let(:admin) { create(:admin) }

  shared_let(:project) { create(:project, enabled_module_names: Setting.default_projects_modules + %w[activity]) }
  shared_let(:work_package) { create(:work_package, project:) }

  shared_let(:merge_request_author) { create(:gitlab_user, username: "i_am_the_author") }
  shared_let(:merge_request_merging_user) { create(:gitlab_user, username: "i_merged") }
  shared_let(:gitlab_html_url) { "http://79dfcd98b723/root/hot_do/-/merge_requests/4" }
  shared_let(:merge_request) do
    create(:gitlab_merge_request, gitlab_html_url:, gitlab_user: merge_request_author)
  end

  def trigger_merge_request_action
    OpenProject::GitlabIntegration::NotificationHandler::MergeRequestHook.new
                                                                    .process(payload)

    merge_request.reload
  end

  let(:mr_description) { "Mentioning OP##{work_package.id}" }
  let(:gitlab_action) { "merge" }
  let(:mr_state) { "merged" }
  let(:mr_draft) { false }

  let(:payload) do
    {
      "open_project_user_id" => gitlab_system_user.id,
      "object_kind" => "merge_request",
      "event_type" => "merge_request",
      "user" => {
        "id" => merge_request_merging_user.gitlab_id,
        "name" => merge_request_merging_user.name,
        "username" => merge_request_merging_user.username,
        "avatar_url" => merge_request_merging_user.avatar_url,
        "email" => "[REDACTED]"
      },
      "object_attributes" => {
        "action" => gitlab_action,
        "assignee_id" => nil,
        "author_id" => 1,
        "created_at" => "2024-03-04 16:09:08 UTC",
        "title" => "A MR title",
        "description" => mr_description,
        "draft" => mr_draft,
        "work_in_progress" => mr_draft,
        "state" => mr_state,
        "head_pipeline_id" => nil,
        "id" => merge_request.gitlab_id,
        "iid" => merge_request.gitlab_id,
        "url" => gitlab_html_url,
        "updated_at" => Time.current.iso8601
      },
      "labels" => [],
      "repository" => {
        "name" => "Hot Do",
        "url" => "git@79dfcd98b723:root/hot_do.git",
        "description" => nil,
        "homepage" => gitlab_html_url
      }
    }
  end

  let(:work_package_page) { Pages::PrimerizedSplitWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  context "when there is a merge request event" do
    before do
      trigger_merge_request_action
      login_as admin
    end

    context "and I visit the work package's activity tab" do
      before do
        work_package_page.visit_tab! "activity"
        work_package_page.ensure_page_loaded
        work_package_page.wait_for_activity_tab
      end

      let(:expected_comment) do
        "MR Merged: Merge request #{merge_request.gitlab_id} " \
          "#{merge_request.title} for #{merge_request.repository} has been merged by " \
          "#{merge_request_merging_user.name}."
      end

      it "renders a comment referencing the Merge Request" do
        activity_tab.expect_journal_notes(text: expected_comment)
      end
    end
  end
end
