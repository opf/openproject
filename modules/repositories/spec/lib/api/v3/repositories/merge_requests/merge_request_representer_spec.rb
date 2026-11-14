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

RSpec.describe API::V3::Repositories::MergeRequests::MergeRequestRepresenter do
  let(:repository_user) { build_stubbed(:repository_user) }
  let(:merge_request) do
    build_stubbed(:repository_merge_request,
                  repository_user:,
                  labels: [{ "title" => "feature", "color" => "#00ff00", "id" => 7 }])
  end
  let(:latest_pipeline) { build_stubbed(:repository_pipeline, :complete, merge_request:) }
  let(:representer) { described_class.new(merge_request, current_user: build_stubbed(:user)) }

  subject(:generated) { representer.to_json }

  before do
    allow(merge_request).to receive(:latest_pipeline).and_return(latest_pipeline)
  end

  it "fulfills the documented schema" do
    expect(generated).to match_json_schema.from_docs("repository_merge_request_model")
  end

  it { is_expected.to be_json_eql("RepositoryMergeRequest".to_json).at_path("_type") }

  it_behaves_like "has a titled link" do
    let(:link) { "self" }
    let(:href) { "/api/v3/repository_merge_requests/#{merge_request.id}" }
    let(:title) { merge_request.title }
  end

  it_behaves_like "has an untitled link" do
    let(:link) { "pipelines" }
    let(:href) { "/api/v3/repository_merge_requests/#{merge_request.id}/repository_pipelines" }
  end

  it_behaves_like "has a titled link" do
    let(:link) { "latestPipeline" }
    let(:href) { "/api/v3/repository_pipelines/#{latest_pipeline.id}" }
    let(:title) { "success" }
  end

  context "without pipelines" do
    let(:latest_pipeline) { nil }

    it_behaves_like "has no link" do
      let(:link) { "latestPipeline" }
    end
  end

  describe "properties" do
    it { is_expected.to be_json_eql(merge_request.id.to_json).at_path("id") }
    it { is_expected.to be_json_eql(merge_request.display_id.to_json).at_path("displayId") }
    it { is_expected.to be_json_eql(merge_request.state.to_json).at_path("state") }
    it { is_expected.to be_json_eql(merge_request.title.to_json).at_path("title") }
    it { is_expected.to be_json_eql(merge_request.description.to_json).at_path("description/raw") }
    it { is_expected.to be_json_eql([{ title: "feature", color: "#00ff00" }].to_json).at_path("labels") }
    it { is_expected.to be_json_eql(merge_request.project_name.to_json).at_path("projectName") }
    it { is_expected.to be_json_eql(merge_request.web_url.to_json).at_path("webUrl") }

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { merge_request.external_updated_at }
      let(:json_path) { "externalUpdatedAt" }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { merge_request.created_at }
      let(:json_path) { "createdAt" }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { merge_request.updated_at }
      let(:json_path) { "updatedAt" }
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
