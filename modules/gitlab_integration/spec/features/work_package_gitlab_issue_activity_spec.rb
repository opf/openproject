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

  shared_let(:issue_author) { create(:gitlab_user, username: "i_am_the_author") }
  shared_let(:issue_closing_user) { create(:gitlab_user, username: "i_closed") }

  shared_let(:gitlab_html_url) { "http://79dfcd98b723/root/hot_do/-/issues/4" }
  shared_let(:issue) do
    create(:gitlab_issue, gitlab_html_url:, gitlab_user: issue_author)
  end

  def trigger_issue_action
    OpenProject::GitlabIntegration::NotificationHandler::IssueHook.new
                                                                    .process(payload)

    issue.reload
  end

  let(:mr_description) { "Mentioning OP##{work_package.id}" }
  let(:gitlab_action) { "close" }
  let(:issue_state) { "closed" }
  let(:labels) { [] }

  let(:payload) do
    {
      "open_project_user_id" => gitlab_system_user.id,
      "object_kind" => "issue",
      "event_type" => "issue",
      "user" => {
        "id" => issue_closing_user.gitlab_id,
        "name" => issue_closing_user.name,
        "username" => issue_closing_user.username,
        "avatar_url" => issue_closing_user.avatar_url,
        "email" => "[REDACTED]"
      },
      "object_attributes" => {
        "action" => gitlab_action,
        "assignee_id" => nil,
        "author_id" => 1,
        "created_at" => "2024-03-04 16:09:08 UTC",
        "title" => "An Issue title",
        "description" => mr_description,
        "draft" => false,
        "work_in_progress" => false,
        "state" => issue_state,
        "id" => issue.gitlab_id,
        "iid" => issue.gitlab_id,
        "head_pipeline_id" => nil,
        "url" => gitlab_html_url,
        "updated_at" => Time.current.iso8601
      },
      "labels" => labels,
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

  context "when there is an issue event" do
    before do
      trigger_issue_action
      login_as admin
    end

    context "and I visit the work package's activity tab" do
      before do
        work_package_page.visit_tab! "activity"
        work_package_page.ensure_page_loaded
      end

      let(:expected_comment) do
        "Issue Closed: Issue #{issue.gitlab_id} #{issue.title} for #{issue.repository} " \
          "has been closed by #{issue_closing_user.name}."
      end

      it "renders a comment referencing the issue" do
        activity_tab.expect_journal_notes(text: expected_comment)
      end
    end
  end
end
