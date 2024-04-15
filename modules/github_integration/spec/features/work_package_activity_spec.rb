# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work Package Activity Tab",
               "Comments by Github",
               :js,
               :with_cuprite do
  shared_let(:github_system_user) { create(:admin, firstname: "Github", lastname: "System User") }
  shared_let(:admin) { create(:admin) }

  shared_let(:project) { create(:project, enabled_module_names: Setting.default_projects_modules + %w[activity]) }
  shared_let(:work_package) { create(:work_package, project:) }

  shared_let(:pull_request_author) { create(:github_user, github_login: "i_am_the_author") }
  shared_let(:pull_request_merging_user) { create(:github_user, github_login: "i_merged") }
  shared_let(:pull_request) do
    create(:github_pull_request,
           github_user: pull_request_author)
  end

  def trigger_pull_request_action
    OpenProject::GithubIntegration::NotificationHandler::PullRequest.new
                                                                    .process(payload)

    pull_request.reload
  end

  let(:payload) do
    {
      "action" => action,
      "open_project_user_id" => github_system_user.id,
      "pull_request" => pull_request_hash,
      "sender" => sender_section_hash
    }
  end

  let(:pull_request_hash) do
    {
      "id" => pull_request.id,
      "number" => pull_request.number,
      "body" => "Mentioning OP##{work_package.id}",
      "title" => pull_request.title,
      "html_url" => pull_request.github_html_url,
      "updated_at" => Time.current.iso8601,
      "state" => state,
      "draft" => false,
      "merged" => merged,
      "merged_by" => merged_by_section_hash,
      "merged_at" => merged_at,
      "comments" => pull_request.comments_count + 1,
      "review_comments" => pull_request.review_comments_count,
      "additions" => pull_request.additions_count,
      "deletions" => pull_request.deletions_count,
      "changed_files" => pull_request.changed_files_count,
      "labels" => pull_request.labels,
      "user" => {
        "id" => pull_request_author.github_id,
        "login" => pull_request_author.github_login,
        "html_url" => pull_request_author.github_html_url,
        "avatar_url" => pull_request_author.github_avatar_url
      },
      "base" => {
        "repo" => {
          "full_name" => "author_user/repo",
          "html_url" => "github.com/author_user/repo"
        }
      }
    }
  end

  let(:sender_section_hash) do
    {
      "login" => "test_user",
      "html_url" => "github.com/test_user"
    }
  end

  let(:work_package_page) { Pages::SplitWorkPackage.new(work_package, project) }

  context "when the pull request is merged" do
    let(:action) { "closed" }

    before do
      trigger_pull_request_action
      login_as admin
    end

    context "and I visit the work package's activity tab" do
      let(:merged) { true }
      let(:merged_by_section_hash) do
        {
          "id" => pull_request_merging_user.github_id,
          "login" => pull_request_merging_user.github_login,
          "html_url" => pull_request_merging_user.github_html_url,
          "avatar_url" => pull_request_merging_user.github_avatar_url
        }
      end
      let(:merged_at) { Time.current.iso8601 }
      let(:state) { "closed" }

      before do
        work_package_page.visit_tab! "activity"
        work_package_page.ensure_page_loaded
      end

      it "renders a comment stating the Pull Request was merged by the merge actor" do
        expected_merge_comment = <<~GITHUB_MERGE_COMMENT.squish
          Merged#{I18n.t('js.github_integration.pull_requests.merged_message',
                         pr_number: pull_request.number,
                         pr_link: pull_request.title,
                         repository_link: pull_request.repository,
                         pr_state: 'merged',
                         github_user_link: pull_request_merging_user.github_login)}
        GITHUB_MERGE_COMMENT

        expect(page).to have_css(".user-comment > .message", text: expected_merge_comment)
      end
    end
  end

  context "when the Work Package is referenced in a Pull Request" do
    let(:action) { "referenced" }

    let(:merged) { false }
    let(:merged_by_section_hash) { {} }
    let(:merged_at) { nil }
    let(:state) { "open" }

    before do
      trigger_pull_request_action
      login_as admin
    end

    context "and I visit the work package's activity tab" do
      before do
        work_package_page.visit_tab! "activity"
        work_package_page.ensure_page_loaded
      end

      it "renders a comment stating the Work Package was referenced in the Pull Request" do
        expected_referenced_comment = <<~GITHUB_REFERENCED_COMMENT.squish
          Referenced#{I18n.t('js.github_integration.pull_requests.referenced_message',
                             pr_number: pull_request.number,
                             pr_link: pull_request.title,
                             repository_link: pull_request.repository,
                             pr_state: 'referenced',
                             github_user_link: pull_request_author.github_login)}
        GITHUB_REFERENCED_COMMENT

        expect(page).to have_css(".user-comment > .message", text: expected_referenced_comment)
      end
    end
  end

  context "when any non-edge-case action is performed on a pull request" do
    let(:action) { "ready_for_review" }

    let(:merged) { false }
    let(:merged_by_section_hash) { {} }
    let(:merged_at) { nil }
    let(:state) { "open" }

    before do
      trigger_pull_request_action
      login_as admin
    end

    context "and I visit the work package's activity tab" do
      before do
        work_package_page.visit_tab! "activity"
        work_package_page.ensure_page_loaded
      end

      it "renders a comment stating that said action was performed on the Pull Request" do
        expected_action_comment = <<~GITHUB_READY_FOR_REVIEW_COMMENT.squish
          Marked Ready For Review#{I18n.t('js.github_integration.pull_requests.message',
                                          pr_number: pull_request.number,
                                          pr_link: pull_request.title,
                                          repository_link: pull_request.repository,
                                          pr_state: 'marked ready for review',
                                          github_user_link: pull_request_author.github_login)}
        GITHUB_READY_FOR_REVIEW_COMMENT

        expect(page).to have_css(".user-comment > .message", text: expected_action_comment)
      end
    end
  end
end
