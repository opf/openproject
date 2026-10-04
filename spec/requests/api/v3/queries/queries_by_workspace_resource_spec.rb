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

RSpec.describe "GET workspaces/:id/queries/default" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project_instance) { create(:project) }
  shared_let(:portfolio_instance) { create(:portfolio) }

  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { [:view_work_packages] }

  current_user { create(:user, member_with_roles: { project => role }) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  context "for a project scope" do
    context "for a project" do
      let(:project) { project_instance }

      it_behaves_like "GET individual query" do
        let(:base_path) { api_v3_paths.query_project_default(project.id) }
        let(:self_path) { api_v3_paths.query_workspace_default(project.id) }

        context "when lacking permissions" do
          let(:permissions) { [] }

          it_behaves_like "unauthorized access"
        end
      end
    end

    context "for a portfolio" do
      let(:project) { portfolio_instance }

      it_behaves_like "GET individual query" do
        let(:base_path) { api_v3_paths.query_project_default(project.id) }
        let(:self_path) { api_v3_paths.query_workspace_default(project.id) }

        context "when lacking permissions" do
          let(:permissions) { [] }

          it_behaves_like "unauthorized access"
        end
      end
    end
  end

  context "for a workspace scope" do
    let(:project) { project_instance }

    it_behaves_like "GET individual query" do
      let(:base_path) { api_v3_paths.query_workspace_default(project.id) }
      context "when lacking permissions" do
        let(:permissions) { [] }

        it_behaves_like "unauthorized access"
      end
    end
  end
end
