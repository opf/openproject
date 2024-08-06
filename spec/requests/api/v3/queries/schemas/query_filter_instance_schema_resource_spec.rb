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
require "rack/test"

RSpec.describe "API v3 Query Filter Schema resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) do
    create(:project).tap do |p|
      create(:category, project: p)
    end
  end
  let(:visible_child) do
    create(:project, parent: project, members: { current_user => role })
  end
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { [:view_work_packages] }
  let(:global_path) { api_v3_paths.query_filter_instance_schemas }
  let(:project_path) { api_v3_paths.query_project_filter_instance_schemas(project.id) }

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  before do
    get path
  end

  subject do
    last_response
  end

  describe "#GET /api/v3/queries/filter_instance_schemas" do
    %i[global
       project].each do |current_path|
      context current_path do
        let(:path) { send :"#{current_path}_path" }

        it "succeeds" do
          expect(subject.status)
            .to eq(200)
        end

        it "returns a collection of schemas" do
          expect(subject.body)
            .to be_json_eql("Collection".to_json)
            .at_path("_type")
          expect(subject.body)
            .to be_json_eql(path.to_json)
            .at_path("_links/self/href")

          expected_type = "QueryFilterInstanceSchema"

          expect(subject.body)
            .to be_json_eql(expected_type.to_json)
            .at_path("_embedded/elements/0/_type")
        end

        context "when the user is not allowed" do
          let(:permissions) { [] }

          it_behaves_like "unauthorized access"
        end
      end
    end

    context "when in a global context" do
      let(:path) { global_path }

      before do
        visible_child
        get path
      end

      it "includes only global specific filter" do
        instance_paths = JSON.parse(subject.body).dig("_embedded", "elements").map { |f| f.dig("_links", "self", "href") }

        expect(instance_paths)
          .not_to include(api_v3_paths.query_filter_instance_schema("category"))

        expect(instance_paths)
          .to include(api_v3_paths.query_filter_instance_schema("project"))

        expect(instance_paths)
          .not_to include(api_v3_paths.query_filter_instance_schema("subprojectId"))
      end
    end

    context "when in a project context" do
      let(:path) { project_path }

      before do
        visible_child
        get path
      end

      it "includes project specific filter" do
        instance_paths = JSON.parse(subject.body).dig("_embedded", "elements").map { |f| f.dig("_links", "self", "href") }

        expect(instance_paths)
          .to include(api_v3_paths.query_filter_instance_schema("category"))

        expect(instance_paths)
          .to include(api_v3_paths.query_filter_instance_schema("project"))

        expect(instance_paths)
          .to include(api_v3_paths.query_filter_instance_schema("subprojectId"))
      end
    end
  end

  describe "#GET /api/v3/queries/filter_instance_schemas/:id" do
    let(:filter_name) { "assignee" }
    let(:path) { api_v3_paths.query_filter_instance_schema(filter_name) }

    it "succeeds" do
      expect(subject.status)
        .to eq(200)
    end

    it "returns the instance schema" do
      expect(subject.body)
        .to be_json_eql(path.to_json)
        .at_path("_links/self/href")
    end

    context "when the user is not allowed" do
      let(:permissions) { [] }

      it_behaves_like "unauthorized access"
    end

    context "when the id is not found" do
      let(:filter_name) { "bogus" }

      it_behaves_like "not found"
    end
  end
end
