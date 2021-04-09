#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::GithubIntegration::GithubPullRequestRepresenter do
  include ::API::V3::Utilities::PathHelper

  subject(:generated) { representer.to_json }

  let(:github_pull_request) do
    FactoryBot.build_stubbed(:github_pull_request,
                             state: 'open',
                             labels: labels).tap do |pr|
      allow(pr)
        .to receive(:github_user)
        .and_return(github_user)

      allow(pr)
        .to receive(:merged_by)
        .and_return(merged_by)

      allow(pr)
        .to receive(:latest_check_runs)
        .and_return(latest_check_runs)
    end
  end
  let(:labels) do
    [
      {
        'name' => 'grey',
        'color' => '#666'
      }
    ]
  end
  let(:github_user) { FactoryBot.build_stubbed(:github_user) }
  let(:merged_by) { FactoryBot.build_stubbed(:github_user) }
  let(:latest_check_runs) { [check_run] }
  let(:check_run) { FactoryBot.build_stubbed(:github_check_run) }
  let(:representer) { described_class.create(github_pull_request, current_user: user) }

  let(:user) { FactoryBot.build_stubbed(:admin) }

  it { is_expected.to include_json('GithubPullRequest'.to_json).at_path('_type') }

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'GithubPullRequest' }
    end

    it_behaves_like 'property', :id do
      let(:value) { github_pull_request.id }
    end

    it_behaves_like 'property', :number do
      let(:value) { github_pull_request.number }
    end

    it_behaves_like 'property', :githubHtmlUrl do
      let(:value) { github_pull_request.github_html_url }
    end

    it_behaves_like 'property', :state do
      let(:value) { github_pull_request.state }
    end

    it_behaves_like 'property', :repository do
      let(:value) { github_pull_request.repository }
    end

    it_behaves_like 'property', :title do
      let(:value) { github_pull_request.title }
    end

    it_behaves_like 'property', :body do
      let(:value) { github_pull_request.body }
    end

    it_behaves_like 'property', :draft do
      let(:value) { github_pull_request.draft }
    end

    it_behaves_like 'property', :merged do
      let(:value) { github_pull_request.merged }
    end

    it_behaves_like 'property', :mergedAt do
      let(:value) { github_pull_request.merged_at }
    end

    it_behaves_like 'property', :commentsCount do
      let(:value) { github_pull_request.comments_count }
    end

    it_behaves_like 'property', :reviewCommentsCount do
      let(:value) { github_pull_request.review_comments_count }
    end

    it_behaves_like 'property', :additionsCount do
      let(:value) { github_pull_request.additions_count }
    end

    it_behaves_like 'property', :deletionsCount do
      let(:value) { github_pull_request.deletions_count }
    end

    it_behaves_like 'property', :changedFilesCount do
      let(:value) { github_pull_request.changed_files_count }
    end

    it_behaves_like 'property', :labels do
      let(:value) { github_pull_request.labels }
    end

    it_behaves_like 'property', :githubUser do
      let(:value) do
        {
          login: github_user.github_login,
          htmlUrl: github_user.github_html_url,
          avatarUrl: github_user.github_avatar_url
        }
      end
    end

    it_behaves_like 'property', :mergedBy do
      let(:value) do
        {
          login: merged_by.github_login,
          htmlUrl: merged_by.github_html_url,
          avatarUrl: merged_by.github_avatar_url
        }
      end
    end

    it_behaves_like 'property', :githubCheckRuns do
      let(:value) do
        [
          {
            htmlUrl: check_run.github_html_url,
            appOwnerAvatarUrl: check_run.github_app_owner_avatar_url,
            name: check_run.name,
            status: check_run.status,
            conclusion: check_run.conclusion,
            outputTitle: check_run.output_title,
            outputSummary: check_run.output_summary,
            detailsUrl: check_run.details_url,
            startedAt: check_run.started_at.iso8601,
            completedAt: check_run.completed_at.iso8601
          }
        ]
      end
    end

    it_behaves_like 'has UTC ISO 8601 date and time' do
      let(:date) { github_pull_request.github_updated_at }
      let(:json_path) { 'githubUpdatedAt' }
    end

    it_behaves_like 'has UTC ISO 8601 date and time' do
      let(:date) { github_pull_request.created_at }
      let(:json_path) { 'createdAt' }
    end

    it_behaves_like 'has UTC ISO 8601 date and time' do
      let(:date) { github_pull_request.updated_at }
      let(:json_path) { 'updatedAt' }
    end
  end

  describe '_links' do
    it { is_expected.to have_json_type(Object).at_path('_links') }
  end

  describe 'caching' do
    before do
      allow(OpenProject::Cache).to receive(:fetch).and_call_original
    end

    it "is based on the representer's cache_key" do
      representer.to_json

      expect(OpenProject::Cache)
        .to have_received(:fetch)
        .with(representer.json_cache_key)
    end

    describe '#json_cache_key' do
      let!(:former_cache_key) { representer.json_cache_key }

      it 'includes the name of the representer class' do
        expect(representer.json_cache_key)
          .to include('API', 'V3', 'GithubIntegration', 'GithubPullRequestRepresenter')
      end

      it 'changes when the locale changes' do
        I18n.with_locale(:fr) do
          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end

      it 'changes when the github_pull_request is updated' do
        github_pull_request.updated_at = Time.zone.now + 20.seconds

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end

      it 'changes when the github_user is updated' do
        github_pull_request.github_user.updated_at = Time.zone.now + 20.seconds

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end

      it 'changes when the merged_by user is updated' do
        github_pull_request.merged_by.updated_at = Time.zone.now + 20.seconds

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end

      it 'changes when the a check_run is updated' do
        github_pull_request.latest_check_runs[0].updated_at = Time.zone.now + 20.seconds

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end
    end
  end
end
