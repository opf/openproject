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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Repositories::Gitlab::NotificationHandler::NoteHook do
  subject(:process) { handler_instance.process(payload) }

  shared_let(:gitlab_system_user) { create(:admin) }
  shared_let(:work_package) { create(:work_package) }
  shared_let(:provider) { create(:repository_provider, url: "http://79dfcd98b723") }

  let(:handler_instance) { described_class.new }
  let(:issue_url) { "http://79dfcd98b723/root/hot_do/-/issues/5" }
  let(:note) { "Related to OP##{work_package.id}" }

  let(:payload) do
    {
      "open_project_user_id" => gitlab_system_user.id,
      "repository_provider_id" => provider.id,
      "object_kind" => "note",
      "event_type" => "note",
      "user" => {
        "id" => 1,
        "name" => "Administrator",
        "username" => "root",
        "avatar_url" => "https://www.gravatar.com/avatar/1?s=80&d=identicon"
      },
      "object_attributes" => {
        "note" => note,
        "noteable_type" => "Issue",
        "description" => note,
        "url" => "#{issue_url}#note_17"
      },
      "issue" => {
        "id" => 1005,
        "iid" => 5,
        "title" => "An Issue title",
        "description" => "The issue's description",
        "state" => "opened",
        "url" => issue_url,
        "updated_at" => "2024-03-04 16:09:08 UTC",
        "labels" => [{ "id" => 1, "title" => "feature", "color" => "#009966" }]
      },
      "repository" => {
        "name" => "Hot Do",
        "homepage" => "http://79dfcd98b723/root/hot_do"
      }
    }
  end

  before do
    allow(handler_instance).to receive(:comment_on_referenced_work_packages).and_return(nil)
  end

  context "with a note on an issue mentioning a work package" do
    it "stores the issue with the issue's own description" do
      expect { process }.to change(Repositories::Issue, :count).by(1)

      expect(Repositories::Issue.last).to have_attributes(
        provider:,
        external_id: "1005",
        display_id: "5",
        web_url: issue_url,
        title: "An Issue title",
        description: "The issue's description",
        labels: [{ "title" => "feature", "color" => "#009966" }],
        work_packages: [work_package]
      )
    end
  end

  context "with a note on an issue not mentioning any work package" do
    let(:note) { "Just a note" }

    it "does not store the issue" do
      expect { process }.not_to change(Repositories::Issue, :count)
    end
  end
end
