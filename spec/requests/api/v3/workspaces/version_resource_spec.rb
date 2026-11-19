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

RSpec.describe "GET workspaces/:id/versions" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, public: false) }
  shared_let(:permitted_user) { create(:user, member_with_permissions: { project => [:view_work_packages] }) }
  shared_let(:unpermitted_user) { create(:user, member_with_permissions: { project => [] }) }
  shared_let(:versions) { create_list(:version, 4, project:) }
  shared_let(:other_versions) { create_list(:version, 2) }

  subject(:response) { last_response }

  shared_context "with versions by workspace" do
    context "for a user with permissions to see the versions" do
      current_user { permitted_user }

      before do
        get get_path
      end

      it_behaves_like "API V3 collection response", 4, 4, "Version"
    end

    context "for a user without permissions to see the versions" do
      current_user { unpermitted_user }

      before do
        get get_path
      end

      it_behaves_like "unauthorized access"
    end
  end

  context "for workspaces/:id/versions" do
    let(:get_path) { api_v3_paths.versions_by_workspace project.id }

    include_context "with versions by workspace"
  end

  context "for projects/:id/versions" do
    let(:get_path) { api_v3_paths.versions_by_project project.id }

    include_context "with versions by workspace"
  end
end
