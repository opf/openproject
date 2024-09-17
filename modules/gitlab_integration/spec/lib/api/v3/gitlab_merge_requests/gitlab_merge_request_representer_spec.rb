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

RSpec.describe API::V3::GitlabMergeRequests::GitlabMergeRequestRepresenter do
  include API::V3::Utilities::PathHelper

  subject(:generated) { representer.to_json }

  let(:gitlab_merge_request) do
    build_stubbed(:gitlab_merge_request,
                  state: "opened",
                  labels:,
                  gitlab_user:,
                  merged_by:).tap do |pr|
      allow(pr)
        .to receive(:latest_pipelines)
        .and_return(latest_pipelines)
    end
  end
  let(:labels) do
    [
      {
        "name" => "grey",
        "color" => "#666"
      }
    ]
  end
  let(:gitlab_user) { build_stubbed(:gitlab_user) }
  let(:merged_by) { build_stubbed(:gitlab_user) }
  let(:latest_pipelines) { [pipeline] }
  let(:pipeline) { build_stubbed(:gitlab_pipeline) }
  let(:representer) { described_class.create(gitlab_merge_request, current_user: user) }

  let(:user) { build_stubbed(:admin) }

  it { is_expected.to include_json("GitlabMergeRequest".to_json).at_path("_type") }

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { "GitlabMergeRequest" }
    end

    it_behaves_like "property", :id do
      let(:value) { gitlab_merge_request.id }
    end

    it_behaves_like "property", :number do
      let(:value) { gitlab_merge_request.number }
    end

    it_behaves_like "property", :htmlUrl do
      let(:value) { gitlab_merge_request.gitlab_html_url }
    end

    it_behaves_like "property", :state do
      let(:value) { gitlab_merge_request.state }
    end

    it_behaves_like "property", :repository do
      let(:value) { gitlab_merge_request.repository }
    end

    it_behaves_like "property", :title do
      let(:value) { gitlab_merge_request.title }
    end

    it_behaves_like "formattable property", :body do
      let(:value) { gitlab_merge_request.body }
    end

    it_behaves_like "property", :draft do
      let(:value) { gitlab_merge_request.draft }
    end

    it_behaves_like "property", :merged do
      let(:value) { gitlab_merge_request.merged }
    end

    it_behaves_like "property", :labels do
      let(:value) { gitlab_merge_request.labels }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { gitlab_merge_request.gitlab_updated_at }
      let(:json_path) { "gitlabUpdatedAt" }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { gitlab_merge_request.created_at }
      let(:json_path) { "createdAt" }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { gitlab_merge_request.updated_at }
      let(:json_path) { "updatedAt" }
    end
  end

  describe "_links" do
    it { is_expected.to have_json_type(Object).at_path("_links") }

    it_behaves_like "has a titled link" do
      let(:link) { "gitlabUser" }
      let(:href) { api_v3_paths.gitlab_user(gitlab_user.id) }
      let(:title) { gitlab_user.gitlab_name }
    end

    it_behaves_like "has a titled link" do
      let(:link) { "mergedBy" }
      let(:href) { api_v3_paths.gitlab_user(merged_by.id) }
      let(:title) { merged_by.gitlab_name }
    end

    it_behaves_like "has a link collection" do
      let(:link) { "pipelines" }
      let(:hrefs) do
        [
          {
            "href" => api_v3_paths.gitlab_pipeline(pipeline.id),
            "title" => pipeline.name
          }
        ]
      end
    end
  end

  describe "caching" do
    before do
      allow(OpenProject::Cache).to receive(:fetch).and_call_original
    end

    it "is based on the representer's cache_key" do
      representer.to_json

      expect(OpenProject::Cache)
        .to have_received(:fetch)
        .with(representer.json_cache_key)
    end

    describe "#json_cache_key" do
      let!(:former_cache_key) { representer.json_cache_key }

      it "includes the name of the representer class" do
        expect(representer.json_cache_key)
          .to include("API", "V3", "GitlabMergeRequests", "GitlabMergeRequestRepresenter")
      end

      it "changes when the locale changes" do
        I18n.with_locale(:fr) do
          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end

      it "changes when the gitlab_merge_request is updated" do
        gitlab_merge_request.updated_at = 20.seconds.from_now

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end

      it "changes when the gitlab_user is updated" do
        gitlab_merge_request.gitlab_user.updated_at = 20.seconds.from_now

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end

      it "changes when the merged_by user is updated" do
        gitlab_merge_request.merged_by.updated_at = 20.seconds.from_now

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end
    end
  end
end
