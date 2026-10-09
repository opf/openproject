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

RSpec.describe API::V3::News::NewsRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:news) do
    build_stubbed(:news,
                  project: workspace,
                  author: current_user)
  end
  let(:workspace) { build_stubbed(:project) }
  let(:current_user) { build_stubbed(:user) }
  let(:embed_links) { true }
  let(:representer) do
    described_class.create(news, current_user:, embed_links:)
  end
  let(:permissions) { all_permissions }
  let(:all_permissions) { %i() }

  subject { representer.to_json }

  before do
    allow(workspace)
      .to receive(:visible?)
            .and_return(true)
  end

  describe "_links" do
    describe "self" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.news news.id }
        let(:title) { news.title }
      end
    end

    describe "project" do
      it_behaves_like "has workspace linked"
    end

    describe "author" do
      it_behaves_like "has a titled link" do
        let(:link) { :author }
        let(:title) { current_user.name }
        let(:href) { api_v3_paths.user current_user.id }
      end
    end
  end

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { "News" }
    end

    it_behaves_like "property", :id do
      let(:value) { news.id }
    end

    it_behaves_like "property", :title do
      let(:value) { news.title }
    end

    it_behaves_like "property", :summary do
      let(:value) { news.summary }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { news.created_at }
      let(:json_path) { "createdAt" }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { news.updated_at }
      let(:json_path) { "updatedAt" }
    end

    it_behaves_like "API V3 formattable", "description" do
      let(:format) { "markdown" }
      let(:raw) { news.description }
      let(:html) { '<p class="op-uc-p">' + news.description + "</p>" }
    end
  end

  describe "_embedded" do
    describe "project" do
      it_behaves_like "has workspace embedded"
    end

    describe "author" do
      let(:embedded_path) { "_embedded/author" }
      let(:embedded_resource) { current_user }
      let(:embedded_resource_type) { "User" }

      it_behaves_like "has the resource embedded"
    end
  end
end
