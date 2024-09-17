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

require File.expand_path("../../../spec_helper", __dir__)

RSpec.describe OpenProject::GithubIntegration::HookHandler do
  subject(:process_webhook) do
    described_class.new
    .tap { journal_counts_before }
    .process("github", OpenStruct.new(env: environment), ActionController::Parameters.new(payload), user)
    .tap { [work_packages[0], work_packages[1], work_packages[2], work_packages[3]].map(&:reload) }
  end

  before do
    allow(Setting).to receive(:host_name).and_return(host_name)
  end

  let(:environment) do
    {
      "HTTP_X_GITHUB_EVENT" => event,
      "HTTP_X_GITHUB_DELIVERY" => "test delivery"
    }
  end
  let(:host_name) { "example.net" }
  let(:user) { create(:user) }
  let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages add_work_package_notes])
  end
  let(:project) do
    create(:project, members: { user => role })
  end

  let(:work_packages) { create_list(:work_package, 4, project:) }
  let(:journal_counts_before) { work_packages.map { |wp| wp.journals.count } }
  let(:journal_counts_after) { work_packages.map { |wp| wp.journals.count } }

  let(:pr_merged) { false }
  let(:pr_draft) { false }
  let(:pr_state) { "open" }
  let(:pr_labels) { [] }

  shared_examples_for "it does not comment on any work package" do
    let(:created_journals) { journal_counts_after.sum - journal_counts_before.sum }

    it "consumes the webhook without commenting on any work package" do
      process_webhook

      expect(created_journals).to be 0
    end
  end

  shared_examples_for "it comments on the first work_package" do
    it "comments only on the first work package" do
      process_webhook

      expect(work_packages[0].journals.count).to be(journal_counts_before[0] + 1)
      expect(work_packages[0].journals.last.notes).to match(journal_entry)

      expect(work_packages[1].journals.count).to be(journal_counts_before[1])
      expect(work_packages[2].journals.count).to be(journal_counts_before[2])
      expect(work_packages[3].journals.count).to be(journal_counts_before[3])
    end
  end

  shared_examples_for "it does not create a pull request" do
    it "creates no GithubPullRequest or GithubUser" do
      expect { process_webhook }.to(
        change(GithubPullRequest, :count).by(0).and(
          change(GithubUser, :count).by(0)
        )
      )
    end
  end

  shared_examples_for "it creates a pull request and github user" do
    it "creates a GithubPullRequest and a GithubUser" do
      expect { process_webhook }.to(change(GithubPullRequest, :count).by(1).and(change(GithubUser, :count).by(1)))

      pull_request = GithubPullRequest.last
      github_user = GithubUser.last
      expect(pull_request).to have_attributes(
        title: "A PR title",
        body: "A PR body mentioning OP##{work_packages[0].id}",
        merged: pr_merged,
        draft: pr_draft,
        state: pr_state,
        labels: pr_labels,
        number: 1,
        additions_count: 123,
        deletions_count: 321,
        comments_count: 22,
        review_comments_count: 33,
        changed_files_count: 12,
        repository: "test_user/webhooks_playground",
        github_user_id: github_user.id
      )
      expect(pull_request.work_packages).to eq [work_packages[0]]

      expect(github_user).to have_attributes(
        github_login: "test_user",
        github_html_url: "https://github.com/test_user",
        github_avatar_url: "https://avatars.githubusercontent.com/u/206108?v=4"
      )
    end
  end

  shared_examples_for "it creates a partial pull request" do
    it "creates a partial GithubPullRequest" do
      expect { process_webhook }.to(
        change(GithubPullRequest, :count).by(1).and(
          change(GithubUser, :count).by(1)
        )
      )

      pull_request = GithubPullRequest.last
      github_user = GithubUser.last

      expect(pull_request).to have_attributes(
        number: 1,
        state: issue_state,
        title: issue_title,
        body: nil,
        merged: nil,
        draft: nil,
        labels: nil,
        additions_count: nil,
        deletions_count: nil,
        comments_count: nil,
        review_comments_count: nil,
        changed_files_count: nil,
        github_user_id: github_user.id
      )
      expect(pull_request.work_packages).to eq [work_packages[0]]

      expect(github_user).to have_attributes(
        github_login: "test_user",
        github_html_url: "https://github.com/test_user",
        github_avatar_url: "https://avatars.githubusercontent.com/u/206108?v=4"
      )
    end
  end

  context "when receiving a webhook for a pull_request event" do
    let(:event) { "pull_request" }

    context "when opened without mentioning any work package" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "opened",
          title: "A PR title",
          body: "A PR body"
        )
      end

      it_behaves_like "it does not comment on any work package"
      it_behaves_like "it does not create a pull request"
    end

    context "when opened and mentioning a work package in the PR title" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "opened",
          title: "A PR title mentioning OP##{work_packages[0].id}",
          body: "A PR body"
        )
      end
      let(:created_journals) { journal_counts_after.sum - journal_counts_before.sum }

      it_behaves_like "it does not comment on any work package"
      it_behaves_like "it does not create a pull request"
    end

    context "when opened and mentioning a work package using its code in the PR body" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "opened",
          title: "A PR title",
          body: "A PR body mentioning OP##{work_packages[0].id}"
        )
      end
      let(:journal_entry) { /<macro.+opened/ }

      it_behaves_like "it comments on the first work_package"
      it_behaves_like "it creates a pull request and github user"
    end

    context "when opened and mentioning many work packages using URLs in the PR body" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "opened",
          title: "A PR title",
          body: "A PR body mentioning
          * http://#{host_name}/wp/#{work_packages[0].id}
          * http://#{host_name}/wp/#{work_packages[0].id} (second mention should not create a second comment)
          * https://#{host_name}/work_packages/#{work_packages[1].id}
          * http://#{host_name}/subdir/wp/#{work_packages[2].id}
          * https://#{host_name}/subdir/work_packages/#{work_packages[3].id}
          "
        )
      end

      it "comments on all mentioned work packages once" do
        process_webhook

        work_packages.each_with_index do |work_package, index|
          expect(work_package.journals.count).to be(journal_counts_before[index] + 1)
          expect(work_package.journals.last.notes).to match(/<macro.+opened/)
        end
      end

      it "creates a GithubPullRequest and a GithubUser" do
        expect { process_webhook }.to(
          change(GithubPullRequest, :count).by(1).and(
            change(GithubUser, :count).by(1)
          )
        )

        pull_request = GithubPullRequest.last
        expect(pull_request).to have_attributes(
          title: "A PR title",
          merged: false,
          draft: false,
          state: "open",
          number: 1
        )
        expect(pull_request.work_packages).to eq work_packages

        github_user = GithubUser.last
        expect(github_user).to have_attributes(
          github_login: "test_user",
          github_html_url: "https://github.com/test_user",
          github_avatar_url: "https://avatars.githubusercontent.com/u/206108?v=4"
        )
      end
    end

    context "when opened mentioning all work_packages with a user having access only to some" do
      let(:project_without_permission) { create(:project) }
      let(:work_packages) do
        [
          create(:work_package, project:),
          create(:work_package, project: project_without_permission),
          create(:work_package, project: project_without_permission),
          create(:work_package, project:)
        ]
      end

      let(:payload) do
        webhook_payload(
          "pull_request",
          "opened",
          title: "A PR title",
          body: "A PR body mentioning
          * OP##{work_packages[0].id}
          * OP##{work_packages[1].id}
          * OP##{work_packages[2].id}
          * OP##{work_packages[3].id}
          "
        )
      end

      it "comments only on work packages with access" do
        process_webhook

        expect(work_packages[0].journals.count).to be(journal_counts_before[0] + 1)
        expect(work_packages[1].journals.count).to be(journal_counts_before[1]) # no permission for this work package
        expect(work_packages[2].journals.count).to be(journal_counts_before[2]) # no permission for this work package
        expect(work_packages[3].journals.count).to be(journal_counts_before[3] + 1)
      end

      it "creates a GithubPullRequest and a GithubUser" do
        expect { process_webhook }.to(
          change(GithubPullRequest, :count).by(1).and(
            change(GithubUser, :count).by(1)
          )
        )

        pull_request = GithubPullRequest.last
        expect(pull_request).to have_attributes(
          title: "A PR title",
          merged: false,
          draft: false,
          state: "open",
          number: 1
        )
        expect(pull_request.work_packages).to eq [work_packages[0], work_packages[3]]

        github_user = GithubUser.last
        expect(github_user).to have_attributes(
          github_login: "test_user",
          github_html_url: "https://github.com/test_user",
          github_avatar_url: "https://avatars.githubusercontent.com/u/206108?v=4"
        )
      end
    end

    context "when opened as draft" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "opened_draft",
          title: "A PR title",
          body: "A PR body mentioning OP##{work_packages[0].id}"
        )
      end
      let(:journal_entry) { /<macro.+opened/ }
      let(:pr_draft) { true }

      it_behaves_like "it comments on the first work_package"
      it_behaves_like "it creates a pull request and github user"
    end

    context "when synchronized" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "synchronize",
          title: "A PR title",
          body: "A PR body mentioning OP##{work_packages[0].id}"
        )
      end

      it_behaves_like "it does not comment on any work package"
      it_behaves_like "it creates a pull request and github user"
    end

    context "when marked as ready_for_review" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "ready_for_review",
          title: "A PR title",
          body: "A PR body mentioning OP##{work_packages[0].id}"
        )
      end
      let(:journal_entry) { /<macro.+ready_for_review/ }

      it_behaves_like "it comments on the first work_package"
      it_behaves_like "it creates a pull request and github user"
    end

    context "when the PR was re-labeled" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "labeled",
          title: "A PR title",
          body: "A PR body mentioning OP##{work_packages[0].id}"
        )
      end
      let(:pr_labels) do
        [
          { "color" => "d73a4a", "name" => "bug" },
          { "color" => "a2eeef", "name" => "enhancement" }
        ]
      end

      it_behaves_like "it does not comment on any work package"
      it_behaves_like "it creates a pull request and github user"
    end

    context "when the PR title was edited" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "edited_title",
          old_title: "The old PR title",
          title: "A PR title",
          body: "A PR body mentioning OP##{work_packages[0].id}"
        )
      end
      let(:journal_entry) { /<macro.+referenced/ }

      it_behaves_like "it comments on the first work_package"
      it_behaves_like "it creates a pull request and github user"
    end

    context "when the PR body was edited" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "edited_body",
          title: "A PR title",
          old_body: "The old PR body",
          body: "A PR body mentioning OP##{work_packages[0].id}"
        )
      end
      let(:journal_entry) { /<macro.+referenced/ }

      it_behaves_like "it comments on the first work_package"
      it_behaves_like "it creates a pull request and github user"
    end

    context "when the PR was converted to draft" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "converted_to_draft",
          title: "A PR title",
          body: "A PR body mentioning OP##{work_packages[0].id}"
        )
      end
      let(:pr_draft) { true }

      it_behaves_like "it does not comment on any work package"
      it_behaves_like "it creates a pull request and github user"
    end

    context "when the PR was closed without merging" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "closed_no_merge",
          title: "A PR title",
          body: "A PR body mentioning OP##{work_packages[0].id}"
        )
      end
      let(:journal_entry) { /<macro.+closed/ }
      let(:pr_state) { "closed" }

      it_behaves_like "it comments on the first work_package"
      it_behaves_like "it creates a pull request and github user"
    end

    context "when the PR was reopened" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "reopened",
          title: "A PR title",
          body: "A PR body mentioning OP##{work_packages[0].id}"
        )
      end
      let(:journal_entry) { /<macro.+opened/ }

      it_behaves_like "it comments on the first work_package"
      it_behaves_like "it creates a pull request and github user"
    end

    context "when the PR was merged" do
      let(:payload) do
        webhook_payload(
          "pull_request",
          "closed_merged",
          title: "A PR title",
          body: "A PR body mentioning OP##{work_packages[0].id}"
        )
      end
      let(:journal_entry) { /<macro.+merged/ }
      let(:pr_state) { "closed" }
      let(:pr_merged) { true }

      it_behaves_like "it comments on the first work_package"
      it_behaves_like "it creates a pull request and github user"

      it "sets the merged_by relation to a GithubUser" do
        process_webhook

        expect(GithubPullRequest.last.merged_by.github_login).to eq "test_user"
      end
    end
  end

  context "when receiving a webhook for an issue_comment event" do
    let(:event) { "issue_comment" }

    context "when an issue comment was created" do
      let(:payload) do
        webhook_payload(
          "issue_comment",
          "create_not_associated_to_pr",
          body: "A comment in an issue mentioning OP##{work_packages[0].id}"
        )
      end

      it_behaves_like "it does not comment on any work package"
      it_behaves_like "it does not create a pull request"
    end

    context "when a PR comment was created" do
      let(:payload) do
        webhook_payload(
          "issue_comment",
          "create",
          body: "A PR comment mentioning OP##{work_packages[0].id}"
        )
      end
      let(:journal_entry) { /<macro.+referenced/ }

      it_behaves_like "it comments on the first work_package"
      it_behaves_like "it creates a partial pull request" do
        let(:issue_state) { payload["issue"]["state"] }
        let(:issue_title) { payload["issue"]["title"] }
      end
    end

    context "when an issue comment was edited" do
      let(:payload) do
        webhook_payload(
          "issue_comment",
          "edited_not_associated_to_pr",
          body: "A comment in an issue mentioning OP##{work_packages[0].id}"
        )
      end

      it_behaves_like "it does not comment on any work package"
      it_behaves_like "it does not create a pull request"
    end

    context "when a PR comment was edited" do
      let(:payload) do
        webhook_payload(
          "issue_comment",
          "edited",
          body: "A PR comment mentioning OP##{work_packages[0].id}"
        )
      end
      let(:journal_entry) { /<macro.+referenced/ }

      it_behaves_like "it comments on the first work_package"
      it_behaves_like "it creates a partial pull request" do
        let(:issue_state) { payload["issue"]["state"] }
        let(:issue_title) { payload["issue"]["title"] }
      end
    end
  end

  context "when receiving a webhook for a ping event" do
    let(:event) { "ping" }
    let(:payload) { webhook_payload("ping", "ping") }

    it_behaves_like "it does not comment on any work package"
    it_behaves_like "it does not create a pull request"
  end

  context "when receiving a webhook for a check_run event" do
    let(:event) { "check_run" }
    # github_id comes from the fixture files
    let(:github_pull_request) { create(:github_pull_request, :open, github_id: 606508565) }

    before { github_pull_request }

    context "when a run was queued but is not associated to a PR" do
      let(:payload) do
        webhook_payload("check_run", "queued_no_associated_pr")
      end

      it_behaves_like "it does not comment on any work package"
      it_behaves_like "it does not create a pull request"

      it "does not create a check run" do
        expect { process_webhook }.not_to(change(GithubCheckRun, :count))
      end
    end

    context "when a run was queued" do
      let(:payload) do
        webhook_payload("check_run", "queued")
      end

      it_behaves_like "it does not comment on any work package"
      it_behaves_like "it does not create a pull request"

      it "creates a check run" do
        expect { process_webhook }.to(change(GithubCheckRun, :count).by(1))
        check_run = GithubCheckRun.last
        expect(check_run).to have_attributes(
          github_pull_request:,
          github_app_owner_avatar_url: "https://avatars.githubusercontent.com/u/9919?v=4",
          status: "queued",
          details_url: "https://github.com/test_user/webhooks_playground/runs/2241417510",
          conclusion: nil
        )
      end
    end

    context "when a run was completed successfully" do
      let(:payload) do
        webhook_payload("check_run", "completed_success")
      end

      it_behaves_like "it does not comment on any work package"
      it_behaves_like "it does not create a pull request"

      it "creates a check run" do
        expect { process_webhook }.to(change(GithubCheckRun, :count).by(1))
        check_run = GithubCheckRun.last
        expect(check_run).to have_attributes(
          github_pull_request:,
          github_app_owner_avatar_url: "https://avatars.githubusercontent.com/u/9919?v=4",
          status: "completed",
          details_url: "https://github.com/test_user/webhooks_playground/runs/2241431836",
          conclusion: "success"
        )
      end
    end

    context "when a run was completed with a failure" do
      let(:payload) do
        webhook_payload("check_run", "completed_failure")
      end

      it_behaves_like "it does not comment on any work package"
      it_behaves_like "it does not create a pull request"

      it "creates a check run" do
        expect { process_webhook }.to(change(GithubCheckRun, :count).by(1))
        check_run = GithubCheckRun.last
        expect(check_run).to have_attributes(
          github_pull_request:,
          github_app_owner_avatar_url: "https://avatars.githubusercontent.com/u/9919?v=4",
          name: "test",
          status: "completed",
          details_url: "https://github.com/test_user/webhooks_playground/runs/2241416592",
          conclusion: "failure"
        )
      end
    end
  end
end
