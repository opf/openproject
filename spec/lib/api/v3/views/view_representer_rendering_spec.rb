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

RSpec.describe API::V3::Views::ViewRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  subject(:generated) { representer.to_json }

  let(:query) { build_stubbed(:query, public: query_public, starred: query_starred) }
  let(:view) { build_stubbed(:view_work_packages_table, query:) }
  let(:current_user) { build_stubbed(:user) }
  let(:query_public) { true }
  let(:query_starred) { true }

  let(:embed_links) { false }

  let(:representer) do
    described_class.create view,
                           current_user:,
                           embed_links:
  end

  describe "properties" do
    describe "_type" do
      it_behaves_like "property", :_type do
        let(:value) { "Views::WorkPackagesTable" }
      end
    end

    describe "id" do
      it_behaves_like "property", :id do
        let(:value) { view.id }
      end
    end

    describe "public" do
      context "with the query being public" do
        it_behaves_like "property", :public do
          let(:value) { true }
        end
      end

      context "with the query being private" do
        let(:query_public) { false }

        it_behaves_like "property", :public do
          let(:value) { false }
        end
      end
    end

    describe "starred" do
      context "with the query being starred" do
        it_behaves_like "property", :starred do
          let(:value) { true }
        end
      end

      context "without the query being starred" do
        let(:query_starred) { false }

        it_behaves_like "property", :starred do
          let(:value) { false }
        end
      end
    end

    describe "name" do
      context "with the query being name" do
        it_behaves_like "property", :name do
          let(:value) { query.name }
        end
      end
    end

    describe "timestamps" do
      it_behaves_like "datetime property", :createdAt do
        let(:value) { view.created_at }
      end

      it_behaves_like "datetime property", :updatedAt do
        let(:value) { view.updated_at }
      end
    end
  end

  describe "_links" do
    describe "self" do
      it_behaves_like "has an untitled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.view view.id }
      end
    end

    describe "query" do
      it_behaves_like "has a titled link" do
        let(:link) { "query" }
        let(:href) { api_v3_paths.query query.id }
        let(:title) { query.name }
      end
    end

    describe "project" do
      it_behaves_like "has a titled link" do
        let(:link) { "project" }
        let(:href) { api_v3_paths.project query.project_id }
        let(:title) { query.project.name }
      end
    end
  end
end
