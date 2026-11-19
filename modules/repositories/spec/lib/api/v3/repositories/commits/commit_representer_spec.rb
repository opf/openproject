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

RSpec.describe API::V3::Repositories::Commits::CommitRepresenter do
  let(:repository_user) { build_stubbed(:repository_user) }
  let(:commit) { build_stubbed(:repository_commit, repository_user:, message: "Fix the bug\n\nIt was nasty.") }
  let(:representer) { described_class.new(commit, current_user: build_stubbed(:user)) }

  subject(:generated) { representer.to_json }

  it "fulfills the documented schema" do
    expect(generated).to match_json_schema.from_docs("repository_commit_model")
  end

  it { is_expected.to be_json_eql("RepositoryCommit".to_json).at_path("_type") }

  it_behaves_like "has a titled link" do
    let(:link) { "self" }
    let(:href) { "/api/v3/repository_commits/#{commit.id}" }
    let(:title) { "Fix the bug" }
  end

  describe "properties" do
    it { is_expected.to be_json_eql(commit.id.to_json).at_path("id") }
    it { is_expected.to be_json_eql(commit.sha.to_json).at_path("sha") }
    it { is_expected.to be_json_eql("plain".to_json).at_path("message/format") }
    it { is_expected.to be_json_eql(commit.message.to_json).at_path("message/raw") }
    it { is_expected.to be_json_eql(commit.author_name.to_json).at_path("authorName") }
    it { is_expected.to be_json_eql(commit.project_name.to_json).at_path("projectName") }
    it { is_expected.to be_json_eql(commit.web_url.to_json).at_path("webUrl") }

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { commit.created_at }
      let(:json_path) { "createdAt" }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { commit.updated_at }
      let(:json_path) { "updatedAt" }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { commit.authored_at }
      let(:json_path) { "authoredAt" }
    end

    describe "author" do
      it { is_expected.to be_json_eql(repository_user.name.to_json).at_path("author/name") }
      it { is_expected.to be_json_eql(repository_user.username.to_json).at_path("author/username") }
      it { is_expected.to be_json_eql(repository_user.avatar_url.to_json).at_path("author/avatarUrl") }

      context "without a repository user" do
        let(:repository_user) { nil }

        it { is_expected.to be_json_eql(nil.to_json).at_path("author") }
      end
    end
  end
end
