# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require "rack/test"
require_relative "../workspaces/update_form_resource_examples"

RSpec.describe "API v3 Program resource update form", content_type: :json do
  describe "POST /api/v3/programs/:id/form" do
    include_examples "APIv3 workspace update form" do
      shared_let(:workspace, reload: true) { create(:program) }

      let(:path) { api_v3_paths.program_form(path_id) }
      let(:workspace_path) { api_v3_paths.program(workspace.id) }

      context "with a portfolio id" do
        let(:workspace) { create(:portfolio, public: true) }

        it_behaves_like "not found"
      end
    end
  end
end
