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

RSpec.describe API::V3::BacklogBuckets::BacklogBucketRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:workspace) { build_stubbed(:project) }
  let(:backlog_bucket) { build_stubbed(:backlog_bucket, name: "My Bucket", project: workspace) }
  let(:current_user) { build_stubbed(:user) }
  let(:embed_links) { true }
  let(:representer) { described_class.create(backlog_bucket, current_user:, embed_links:) }

  subject(:generated) { representer.to_json }

  it { is_expected.to include_json("BacklogBucket".to_json).at_path("_type") }

  describe "links" do
    it { is_expected.to have_json_type(Object).at_path("_links") }

    describe "self" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.backlog_bucket(backlog_bucket.id) }
        let(:title) { backlog_bucket.name }
      end
    end

    describe "definingWorkspace" do
      it_behaves_like "has workspace linked" do
        let(:link) { "definingWorkspace" }
      end
    end
  end

  describe "properties" do
    describe "_type" do
      it_behaves_like "property", :_type do
        let(:value) { "BacklogBucket" }
      end
    end

    describe "id" do
      it_behaves_like "property", :id do
        let(:value) { backlog_bucket.id }
      end
    end

    describe "name" do
      it_behaves_like "property", :name do
        let(:value) { backlog_bucket.name }
      end
    end

    describe "createdAt" do
      it_behaves_like "has UTC ISO 8601 date and time" do
        let(:date) { backlog_bucket.created_at }
        let(:json_path) { "createdAt" }
      end
    end

    describe "updatedAt" do
      it_behaves_like "has UTC ISO 8601 date and time" do
        let(:date) { backlog_bucket.updated_at }
        let(:json_path) { "updatedAt" }
      end
    end
  end

  describe "embedded" do
    it_behaves_like "has workspace embedded" do
      let(:embedded_path) { "_embedded/definingWorkspace" }
    end
  end
end
