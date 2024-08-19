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

RSpec.describe API::V3::GithubPullRequests::GithubUserRepresenter do
  include API::V3::Utilities::PathHelper

  subject(:generated) { representer.to_json }

  let(:github_user) { build_stubbed(:github_user) }
  let(:representer) { described_class.create(github_user, current_user: user) }

  let(:user) { build_stubbed(:admin) }

  it { is_expected.to include_json("GithubUser".to_json).at_path("_type") }

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { "GithubUser" }
    end

    it_behaves_like "property", :login do
      let(:value) { github_user.github_login }
    end

    it_behaves_like "property", :htmlUrl do
      let(:value) { github_user.github_html_url }
    end

    it_behaves_like "property", :avatarUrl do
      let(:value) { github_user.github_avatar_url }
    end
  end

  describe "_links" do
    it { is_expected.to have_json_type(Object).at_path("_links") }
    it { is_expected.to have_json_path("_links/self/href") }
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
          .to include("API", "V3", "GithubPullRequests", "GithubUserRepresenter")
      end

      it "changes when the locale changes" do
        I18n.with_locale(:fr) do
          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end

      it "changes when the github_user is updated" do
        github_user.updated_at = 20.seconds.from_now

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end
    end
  end
end
