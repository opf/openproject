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

  shared_let(:merge_request_author) { create(:gitlab_user, gitlab_username: "i_am_the_author") }
  shared_let(:merge_request_merging_user) { create(:gitlab_user, gitlab_username: "i_merged") }
  shared_let(:merge_request) do
    create(:gitlab_merge_request,
           gitlab_user: merge_request_author)
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
        "name" => merge_request_merging_user.gitlab_name,
        "username" => merge_request_merging_user.gitlab_username,
        "avatar_url" => merge_request_merging_user.gitlab_avatar_url,
        "email" => merge_request_merging_user.gitlab_email
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
        "url" => "http://79dfcd98b723/root/hot_do/-/merge_requests/4",
        "updated_at" => Time.current.iso8601
      },
      "labels" => [],
      "repository" => {
        "name" => "Hot Do",
        "url" => "git@79dfcd98b723:root/hot_do.git",
        "description" => nil,
        "homepage" => "http://79dfcd98b723/root/hot_do/-/merge_requests/4"
      }
    }
  end

  let(:work_package_page) { Pages::SplitWorkPackage.new(work_package, project) }

  context "when there is a merge request event" do
    before do
      trigger_merge_request_action
      login_as admin
    end

    context "and I visit the work package's activity tab" do
      before do
        work_package_page.visit_tab! "activity"
        work_package_page.ensure_page_loaded
      end

      let(:expected_comment) do
        "MR Merged: Merge request #{merge_request.gitlab_id} " \
          "#{merge_request.title} for #{merge_request.repository} has been merged by " \
          "#{merge_request_merging_user.gitlab_name}."
      end

      it "renders a comment referencing the Merge Request" do
        expect(page).to have_css(".user-comment > .message", text: expected_comment)
      end
    end
  end
end
