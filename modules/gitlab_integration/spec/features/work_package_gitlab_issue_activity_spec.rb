# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work Package Activity Tab",
               "Comments by Gitlab",
               :js,
               :with_cuprite do
  shared_let(:gitlab_system_user) { create(:admin, firstname: "Gitlab", lastname: "System User") }
  shared_let(:admin) { create(:admin) }

  shared_let(:project) { create(:project, enabled_module_names: Setting.default_projects_modules + %w[activity]) }
  shared_let(:work_package) { create(:work_package, project:) }

  shared_let(:issue_author) { create(:gitlab_user, gitlab_username: "i_am_the_author") }
  shared_let(:issue_closing_user) { create(:gitlab_user, gitlab_username: "i_closed") }

  shared_let(:issue) do
    create(:gitlab_issue,
           gitlab_user: issue_author)
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
        "name" => issue_closing_user.gitlab_name,
        "username" => issue_closing_user.gitlab_username,
        "avatar_url" => issue_closing_user.gitlab_avatar_url,
        "email" => issue_closing_user.gitlab_email
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
        "url" => "http://79dfcd98b723/root/hot_do/-/issues/4",
        "updated_at" => Time.current.iso8601
      },
      "labels" => labels,
      "repository" => {
        "name" => "Hot Do",
        "url" => "git@79dfcd98b723:root/hot_do.git",
        "description" => nil,
        "homepage" => "http://79dfcd98b723/root/hot_do/-/issues/4"
      }
    }
  end

  let(:work_package_page) { Pages::SplitWorkPackage.new(work_package, project) }

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
          "has been closed by #{issue_closing_user.gitlab_name}."
      end

      it "renders a comment referencing the issue" do
        expect(page).to have_css(".user-comment > .message", text: expected_comment)
      end
    end
  end
end
