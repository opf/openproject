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
require "rack/test"

RSpec.describe "GET workspaces/:id/queries/schema" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project) }
  let(:permissions) { [:view_work_packages] }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  current_user { user }

  shared_context "as workspace schema" do
    subject { last_response }

    before do
      get path
    end

    it "succeeds" do
      expect(subject.status)
        .to be(200)
    end

    it "returns the schema" do
      expect(subject.body)
        .to be_json_eql(api_v3_paths.query_workspace_schema(project.id).to_json)
        .at_path("_links/self/href")
    end

    context "when user not allowed" do
      let(:permissions) { [] }

      it_behaves_like "unauthorized access"
    end
  end

  context "for the project path" do
    let(:path) { api_v3_paths.query_project_schema(project.id) }

    include_context "as workspace schema"
  end

  context "for the workspace path" do
    let(:path) { api_v3_paths.query_workspace_schema(project.id) }

    include_context "as workspace schema"
  end
end
