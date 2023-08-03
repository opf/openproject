# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work Package Activity Tab',
               'Comments by Github',
               :js,
               :with_cuprite do
  shared_let(:github_system_user) { create(:admin) }
  shared_let(:admin) { create(:admin) }

  shared_let(:project) { create(:project, enabled_module_names: Setting.default_projects_modules + %w[activity]) }
  shared_let(:work_package) { create(:work_package, project:) }

  shared_let(:pull_request_author) { create(:github_user) }
  shared_let(:pull_request_merging_user) { create(:github_user) }
  shared_let(:pull_request) do
    create(:github_pull_request,
           github_user: pull_request_author)
  end

  def upsert_pull_request_with_merge
    OpenProject::GithubIntegration::NotificationHandler::PullRequest.new
                                                                    .process(closed_merged_payload)

    pull_request.reload
  end

  let(:closed_merged_payload) do
    {
      'action' => 'closed',
      'open_project_user_id' => github_system_user.id,
      'pull_request' => pull_request_hash,
      'sender' => sender_section_hash
    }
  end

  let(:pull_request_hash) do
    {
      'id' => pull_request.id,
      'number' => pull_request.number,
      'body' => "Mentioning OP##{work_package.id}",
      'title' => pull_request.title,
      'html_url' => pull_request.github_html_url,
      'updated_at' => Time.current.iso8601,
      'state' => 'closed',
      'draft' => false,
      'merged' => true,
      'merged_by' => merged_by_section_hash,
      'merged_at' => Time.current.iso8601,
      'comments' => pull_request.comments_count + 1,
      'review_comments' => pull_request.review_comments_count,
      'additions' => pull_request.additions_count,
      'deletions' => pull_request.deletions_count,
      'changed_files' => pull_request.changed_files_count,
      'labels' => pull_request.labels,
      'user' => author_section_hash,
      'base' => base_section_hash
    }
  end

  let(:merged_by_section_hash) do
    {
      'id' => pull_request_merging_user.github_id,
      'login' => pull_request_merging_user.github_login,
      'html_url' => pull_request_merging_user.github_html_url,
      'avatar_url' => pull_request_merging_user.github_avatar_url
    }
  end

  let(:author_section_hash) do
    {
      'id' => pull_request_author.github_id,
      'login' => pull_request_author.github_login,
      'html_url' => pull_request_author.github_html_url,
      'avatar_url' => pull_request_author.github_avatar_url
    }
  end

  let(:sender_section_hash) do
    {
      'login' => 'test_user',
      'html_url' => 'github.com/test_user'
    }
  end

  let(:base_section_hash) do
    {
      'repo' => {
        'full_name' => 'author_user/repo',
        'html_url' => 'github.com/author_user/repo'
      }
    }
  end

  let(:work_package_page) { Pages::SplitWorkPackage.new(work_package, project) }

  before do
    login_as admin
  end

  context 'when the pull request is merged' do
    before do
      upsert_pull_request_with_merge
    end

    context "and I visit the work package's activity tab" do
      before do
        work_package_page.visit_tab! 'activity'
        work_package_page.ensure_page_loaded
      end

      it 'renders a comment stating the Pull Request was merged by the merge actor' do
        expected_merge_comment = <<~GITHUB_MERGE_COMMENT.squish
          Merged#{I18n.t('js.github_integration.pull_requests.message',
                         pr_number: pull_request.number,
                         pr_link: pull_request.title,
                         repository_link: pull_request.repository,
                         pr_state: 'merged',
                         github_user_link: pull_request_merging_user.github_login)}
        GITHUB_MERGE_COMMENT

        expect(page).to have_selector('.user-comment > .message', text: expected_merge_comment)
      end
    end
  end
end
