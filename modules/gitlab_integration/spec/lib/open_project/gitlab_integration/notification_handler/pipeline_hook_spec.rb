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

RSpec.describe OpenProject::GitlabIntegration::NotificationHandler::PipelineHook do
  subject(:process) { handler_instance.process(payload) }

  shared_let(:gitlab_system_user) { create(:admin) }
  shared_let(:gitlab_merge_request) { create(:gitlab_merge_request) }

  let(:handler_instance) { described_class.new }
  let(:upsert_service) { OpenProject::GitlabIntegration::Services::UpsertPipeline.new }

  let(:payload) do
    {
      "open_project_user_id" => gitlab_system_user.id,
      "object_kind" => "pipeline",
      "event_type" => "pipeline",
      "user" => {
        "id" => 1,
        "name" => "Administrator",
        "username" => "root",
        "avatar_url" => "https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon",
        "email" => "[REDACTED]"
      },
      "object_attributes" => {
        "id" => 5,
        "iid" => 5,
        "name" => nil,
        "ref" => "task/42-test-hooks",
        "tag" => false,
        "sha" => "4bf4cebeddac33ebfdd5f4cbbab44ee6cc9b1906",
        "before_sha" => "ec01ed498c3736fe6edb21cdd08bee437120adab",
        "source" => "push",
        "status" => "failed",
        "detailed_status" => "failed",
        "stages" => [
          "test"
        ],
        "created_at" => "2024-03-02 09:01:05 UTC",
        "finished_at" => "2024-03-02 11:00:07 UTC",
        "duration" => nil,
        "queued_duration" => nil,
        "variables" => [],
        "url" => "http://79dfcd98b723/root/hot_do/-/pipelines/5"
      },
      "merge_request" => {
        "iid" => gitlab_merge_request.gitlab_id,
        "id" => gitlab_merge_request.gitlab_id,
        "title" => "Update .gitlab-ci.yml file",
        "ref_path" => "/root/hot_do/-/merge_requests/1",
        "source_branch" => "task/42-test-hooks",
        "source_project_id" => 1,
        "target_branch" => "main",
        "target_project_id" => 1
      },
      "project" => {
        "id" => 1,
        "name" => "Hot Do",
        "description" => nil,
        "web_url" => "http://79dfcd98b723/root/hot_do",
        "avatar_url" => nil,
        "git_ssh_url" => "git@79dfcd98b723:root/hot_do.git",
        "git_http_url" => "http://79dfcd98b723/root/hot_do.git",
        "namespace" => "Administrator",
        "visibility_level" => 20,
        "path_with_namespace" => "root/hot_do",
        "default_branch" => "main",
        "ci_config_path" => nil
      },
      "builds" => [
        {
          "id" => 34,
          "stage" => "test",
          "name" => "unit-test-job",
          "status" => "skipped",
          "created_at" => "2024-03-02 09:01:05 UTC",
          "started_at" => nil,
          "finished_at" => nil,
          "duration" => nil,
          "queued_duration" => nil,
          "failure_reason" => nil,
          "when" => "on_success",
          "manual" => false,
          "allow_failure" => false,
          "user" => {
            "id" => 1,
            "name" => "Administrator",
            "username" => "root",
            "avatar_url" => "https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon",
            "email" => "[REDACTED]"
          },
          "runner" => nil,
          "artifacts_file" => {
            "filename" => nil,
            "size" => nil
          },
          "environment" => nil
        }
      ]
    }
  end

  before do
    allow(handler_instance).to receive(:comment_on_referenced_work_packages).and_return(nil)
    allow(OpenProject::GitlabIntegration::Services::UpsertPipeline).to receive(:new).and_return(upsert_service)
    allow(upsert_service).to receive(:call).and_call_original
  end

  context "with a new pipeline" do
    it "calls the pipeline upsert service" do
      expect { process }.to change(GitlabPipeline, :count).by(1)
      expect(upsert_service).to have_received(:call)
        .with(a_kind_of(OpenProject::GitlabIntegration::NotificationHandler::Helper::Payload),
              merge_request: gitlab_merge_request)
    end
  end
end
