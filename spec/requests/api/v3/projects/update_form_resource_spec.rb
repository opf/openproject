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
require_relative "../workspaces/update_form_resource_examples"

RSpec.describe "API v3 Project resource update form", content_type: :json do
  describe "POST /api/v3/projects/:id/form" do
    context "for a project" do
      include_examples "APIv3 workspace update form" do
        shared_let(:workspace, reload: true) { create(:project) }

        let(:path) { api_v3_paths.project_form(path_id) }
        let(:workspace_path) { api_v3_paths.project(workspace.id) }
      end
    end

    context "for a portfolio" do
      include_examples "APIv3 workspace update form" do
        shared_let(:workspace, reload: true) { create(:portfolio) }

        let(:path) { api_v3_paths.project_form(path_id) }
        let(:workspace_path) { api_v3_paths.portfolio(workspace.id) }
      end
    end
  end
end
