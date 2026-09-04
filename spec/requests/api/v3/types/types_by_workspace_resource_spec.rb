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
require "rack/test"

RSpec.describe "/api/v3/projects/:id/types" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:requested_project) { project }
  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end

  let!(:irrelevant_types) { create_list(:type, 4) }
  let!(:expected_types) { create_list(:type, 4) }

  shared_context "for types by workspace" do
    subject(:response) { last_response }

    before do
      expected_types.each { |type| project.project_types.create!(type:) }
    end

    context "for a logged in user" do
      before do
        allow(User).to receive(:current).and_return current_user

        get get_path
      end

      it_behaves_like "API V3 collection response", 4, 4, "Type" do
        let(:elements) { expected_types }
      end

      context "in a foreign project" do
        let(:requested_project) { create(:project, public: false) }

        it_behaves_like "not found"
      end
    end

    context "for not logged in user" do
      before do
        get get_path
      end

      it_behaves_like "not found response based on login_required"
    end
  end

  context "when using the projects route" do
    context "for a project" do
      let(:project) { create(:project, no_types: true) }
      let(:get_path) { api_v3_paths.types_by_project requested_project.id }

      include_context "for types by workspace"
    end

    context "for a portfolio" do
      let(:project) { create(:portfolio, no_types: true) }
      let(:get_path) { api_v3_paths.types_by_project requested_project.id }

      include_context "for types by workspace"
    end
  end

  context "when using the workspaces route" do
    let(:project) { create(:portfolio, no_types: true) }
    let(:get_path) { api_v3_paths.types_by_workspace requested_project.id }

    include_context "for types by workspace"
  end
end
