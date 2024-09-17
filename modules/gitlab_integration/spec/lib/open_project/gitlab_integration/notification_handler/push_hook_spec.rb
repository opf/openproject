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

RSpec.describe OpenProject::GitlabIntegration::NotificationHandler::PushHook do
  subject(:process) { handler_instance.process(payload) }

  shared_let(:gitlab_system_user) { create(:admin) }
  shared_let(:work_package) { create(:work_package) }

  let(:handler_instance) { described_class.new }

  let(:commit_title) { "Mentioning OP##{work_package.id}" }
  let(:commit_message) { "Mentioning OP##{work_package.id}\n\nSome commit message\n" }
  let(:payload) do
    {
      "object_kind" => "push",
      "event_name" => "push",
      "before" => "76e703f64c13245bdacf66737d99a52f08f3d727",
      "after" => "a265d6b7bcf836b77ed9e32f824b231585c6a355",
      "ref" => "refs/heads/main",
      "ref_protected" => true,
      "checkout_sha" => "a265d6b7bcf836b77ed9e32f824b231585c6a355",
      "message" => nil,
      "user_id" => 1,
      "user_name" => "Administrator",
      "user_username" => "root",
      "user_email" => nil,
      "user_avatar" => "https://www.gravatar.com/avatar/65a222b844ced567fe0ed2594c0b4abdf62efa1322a385c919c41e7bbc16d4fc?s=80&d=identicon",
      "project_id" => 1,
      "project" =>
        {
          "id" => 1,
          "name" => "Test",
          "description" => nil,
          "web_url" => "http://c7e7cd2d54c3/openprojecttest/test",
          "avatar_url" => nil,
          "git_ssh_url" => "git@c7e7cd2d54c3:openprojecttest/test.git",
          "git_http_url" => "http://c7e7cd2d54c3/openprojecttest/test.git",
          "namespace" => "openprojecttest",
          "visibility_level" => 10,
          "path_with_namespace" => "openprojecttest/test",
          "default_branch" => "main",
          "ci_config_path" => nil,
          "homepage" => "http://c7e7cd2d54c3/openprojecttest/test",
          "url" => "git@c7e7cd2d54c3:openprojecttest/test.git",
          "ssh_url" => "git@c7e7cd2d54c3:openprojecttest/test.git",
          "http_url" => "http://c7e7cd2d54c3/openprojecttest/test.git"
        },
      "commits" => [
        {
          "id" => "a265d6b7bcf836b77ed9e32f824b231585c6a355",
          "message" => commit_message,
          "title" => commit_title,
          "timestamp" => "2024-07-22T11:18:29+02:00",
          "url" => "http://c7e7cd2d54c3/openprojecttest/test/-/commit/a265d6b7bcf836b77ed9e32f824b231585c6a355",
          "author" => { "name" => "Some committer", "email" => "some_committer@example.com" },
          "added" => [],
          "modified" => ["CHANGELOG"],
          "removed" => []
        }
      ],
      "total_commits_count" => 1,
      "push_options" => {},
      "repository" =>
        {
          "name" => "Test",
          "url" => "git@c7e7cd2d54c3:openprojecttest/test.git",
          "description" => nil,
          "homepage" => "http://c7e7cd2d54c3/openprojecttest/test",
          "git_http_url" => "http://c7e7cd2d54c3/openprojecttest/test.git",
          "git_ssh_url" => "git@c7e7cd2d54c3:openprojecttest/test.git",
          "visibility_level" => 10
        },
      "open_project_user_id" => gitlab_system_user.id,
      "gitlab_event" => "push_hook"
    }
  end

  before do
    allow(handler_instance).to receive(:comment_on_referenced_work_packages).and_return(nil)
  end

  context "with a regular push" do
    let(:comment) do
      "**Pushed in refs/heads/main:** [Administrator]" \
        "(https://www.gravatar.com/avatar/65a222b844ced567fe0ed2594c0b4abdf62efa1322a385c919c41e7bbc16d4fc?s=80&d=identicon) " \
        "pushed [a265d6b7](http://c7e7cd2d54c3/openprojecttest/test/-/commit/a265d6b7bcf836b77ed9e32f824b231585c6a355) " \
        "to [Test](http://c7e7cd2d54c3/openprojecttest/test) at 2024-07-22T11:18:29+02:00:" \
        "\nMentioning OP##{work_package.id}\n\nSome commit message\n\n"
    end

    it "adds a comment to the work packages" do
      process
      expect(handler_instance).to have_received(:comment_on_referenced_work_packages).with(
        [work_package],
        gitlab_system_user,
        comment
      )
    end

    context "when no commit message is given in the payload" do
      before do
        payload["commits"][0]["message"] = nil
      end

      let(:comment) do
        "**Pushed in refs/heads/main:** [Administrator]" \
          "(https://www.gravatar.com/avatar/65a222b844ced567fe0ed2594c0b4abdf62efa1322a385c919c41e7bbc16d4fc?s=80&d=identicon) " \
          "pushed [a265d6b7](http://c7e7cd2d54c3/openprojecttest/test/-/commit/a265d6b7bcf836b77ed9e32f824b231585c6a355) " \
          "to [Test](http://c7e7cd2d54c3/openprojecttest/test) at 2024-07-22T11:18:29+02:00:\nMentioning OP##{work_package.id}\n"
      end

      it "does not raise (Bugfix)" do
        expect { process }.not_to raise_error
        expect(handler_instance).to have_received(:comment_on_referenced_work_packages).with(
          [work_package],
          gitlab_system_user,
          comment
        )
      end
    end
  end
end
