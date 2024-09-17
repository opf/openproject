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
require_module_spec_helper

RSpec.describe OpenProject::GitlabIntegration::NotificationHandler::MergeRequestHook do
  subject(:process) { handler_instance.process(payload) }

  shared_let(:gitlab_system_user) { create(:admin) }
  shared_let(:work_package) { create(:work_package) }

  let(:handler_instance) { described_class.new }
  let(:upsert_service) { OpenProject::GitlabIntegration::Services::UpsertMergeRequest.new }
  let(:gitlab_merge_request) { GitlabMergeRequest.find_by_gitlab_identifiers(id: 4) }

  let(:mr_description) { "Mentioning OP##{work_package.id}" }
  let(:gitlab_action) { "open" }
  let(:mr_state) { "opened" }
  let(:mr_draft) { false }
  let(:labels) { [] }

  let(:payload) do
    {
      "open_project_user_id" => gitlab_system_user.id,
      "object_kind" => "merge_request",
      "event_type" => "merge_request",
      "user" => {
        "id" => 1,
        "name" => "Administrator",
        "username" => "root",
        "avatar_url" => "https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon",
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
        "id" => 4,
        "iid" => 4,
        "url" => "http://79dfcd98b723/root/hot_do/-/merge_requests/4",
        "updated_at" => Time.current.iso8601
      },
      "labels" => labels,
      "repository" => {
        "name" => "Hot Do",
        "url" => "git@79dfcd98b723:root/hot_do.git",
        "description" => nil,
        "homepage" => "http://79dfcd98b723/root/hot_do/-/merge_requests/4"
      }
    }
  end

  before do
    allow(handler_instance).to receive(:comment_on_referenced_work_packages).and_return(nil)
    allow(OpenProject::GitlabIntegration::Services::UpsertMergeRequest).to receive(:new).and_return(upsert_service)
    allow(upsert_service).to receive(:call).and_call_original
  end

  shared_examples_for "not adding a comment" do
    it "does not add comments to work packages" do
      process
      expect(handler_instance).not_to have_received(:comment_on_referenced_work_packages)
    end
  end

  shared_examples_for "adding a comment" do
    it "adds a comment to the work packages" do
      process
      expect(handler_instance).to have_received(:comment_on_referenced_work_packages).with(
        [work_package],
        gitlab_system_user,
        comment
      )
    end

    context "when no description is given in the payload" do
      before do
        payload["object_attributes"]["description"] = nil
      end

      it "does not raise (Bugfix)" do
        expect { process }.not_to raise_error
        expect(handler_instance).to have_received(:comment_on_referenced_work_packages).with(
          [],
          gitlab_system_user,
          comment
        )
      end
    end
  end

  shared_examples_for "calls the merge request upsert service" do
    it "calls the merge request upsert service" do
      process
      expect(upsert_service).to have_received(:call)
        .with(a_kind_of(OpenProject::GitlabIntegration::NotificationHandler::Helper::Payload), work_packages: [work_package])
    end

    context "when no work_package was mentioned" do
      let(:mr_description) { "some text that does not mention any work package" }

      it "does not call the merge request upsert service" do
        process
        expect(upsert_service).not_to have_received(:call)
      end
    end
  end

  context "with an opened action" do
    let(:comment) do
      "**MR Opened:** Merge request 4 [A MR title](http://79dfcd98b723/root/hot_do/-/merge_requests/4) for " \
        "[Hot Do](git@79dfcd98b723:root/hot_do.git) has been opened by " \
        "[Administrator](https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon).\n"
    end

    it_behaves_like "adding a comment"
    it_behaves_like "calls the merge request upsert service"
  end

  context "with a closed action" do
    let(:gitlab_action) { "close" }
    let(:mr_state) { "closed" }

    let(:comment) do
      "**MR Closed:** Merge request 4 [A MR title](http://79dfcd98b723/root/hot_do/-/merge_requests/4) for " \
        "[Hot Do](git@79dfcd98b723:root/hot_do.git) has been closed by " \
        "[Administrator](https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon).\n"
    end

    it_behaves_like "adding a comment"
    it_behaves_like "calls the merge request upsert service"
  end

  context "when the MR was merged" do
    let(:gitlab_action) { "merge" }
    let(:mr_state) { "merged" }

    let(:comment) do
      "**MR Merged:** Merge request 4 [A MR title](http://79dfcd98b723/root/hot_do/-/merge_requests/4) for " \
        "[Hot Do](git@79dfcd98b723:root/hot_do.git) has been merged by " \
        "[Administrator](https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon).\n"
    end

    it_behaves_like "adding a comment"
    it_behaves_like "calls the merge request upsert service"

    context "when the work package is already known to the GitlabMergeRequest" do
      let!(:gitlab_merge_request) { create(:gitlab_merge_request, gitlab_id: 4, work_packages: [work_package]) }

      it_behaves_like "adding a comment"

      it "calls the merge request upsert service" do
        expect { process }.to change { gitlab_merge_request.reload.state }.from("opened").to("merged")
        expect(upsert_service).to have_received(:call).with(
          a_kind_of(OpenProject::GitlabIntegration::NotificationHandler::Helper::Payload), work_packages: [work_package]
        )
      end
    end
  end

  context "when the MR is converted to draft" do
    let(:gitlab_action) { "update" }
    let(:mr_state) { "opened" }
    let(:mr_draft) { true }

    it_behaves_like "not adding a comment"
    it_behaves_like "calls the merge request upsert service"
  end

  context "with a labeled action" do
    let(:gitlab_action) { "update" }
    let(:mr_state) { "opened" }

    let(:labels) do
      [
        {
          "id" => 1,
          "title" => "feature",
          "color" => "#009966",
          "project_id" => 1,
          "created_at" => "2024-03-04 14:30:36 UTC",
          "updated_at" => "2024-03-04 14:30:36 UTC",
          "template" => false,
          "description" => nil,
          "type" => "ProjectLabel",
          "group_id" => nil,
          "lock_on_merge" => false
        },
        {
          "id" => 2,
          "title" => "needs review",
          "color" => "#9400d3",
          "project_id" => 1,
          "created_at" => "2024-03-04 15:46:50 UTC",
          "updated_at" => "2024-03-04 15:46:50 UTC",
          "template" => false,
          "description" => nil,
          "type" => "ProjectLabel",
          "group_id" => nil,
          "lock_on_merge" => false
        }
      ]
    end

    it_behaves_like "not adding a comment"

    it "calls the merge request upsert service with all work_packages" do
      gitlab_merge_request = process.reload
      expect(gitlab_merge_request.labels).to eq([{ "title" => "feature", "color" => "#009966" },
                                                 { "title" => "needs review", "color" => "#9400d3" }])

      expect(upsert_service).to have_received(:call).with(a_kind_of(OpenProject::GitlabIntegration::NotificationHandler::Helper::Payload),
                                                          work_packages: [work_package])
    end
  end

  context "when the MR is ready for review" do
    let(:gitlab_action) { "update" }
    let(:mr_state) { "opened" }
    let(:mr_draft) { false }

    let(:comment) do
      "**MR Opened:** Merge request 4 [A MR title](http://79dfcd98b723/root/hot_do/-/merge_requests/4) for " \
        "[Hot Do](git@79dfcd98b723:root/hot_do.git) has been opened by " \
        "[Administrator](https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon).\n"
    end

    before { create(:gitlab_merge_request, gitlab_id: 4, work_packages: [work_package]) }

    it_behaves_like "not adding a comment"

    it "calls the merge request upsert service" do
      process
      expect(upsert_service).to have_received(:call)
        .with(a_kind_of(OpenProject::GitlabIntegration::NotificationHandler::Helper::Payload), work_packages: [work_package])
    end
  end

  context "with a reopened action" do
    let(:gitlab_action) { "reopen" }
    let(:mr_state) { "opened" }

    let(:comment) do
      "**MR Reopened:** Merge request 4 [A MR title](http://79dfcd98b723/root/hot_do/-/merge_requests/4) for " \
        "[Hot Do](git@79dfcd98b723:root/hot_do.git) has been reopened by " \
        "[Administrator](https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon).\n"
    end

    it_behaves_like "adding a comment"
    it_behaves_like "calls the merge request upsert service"
  end
end
