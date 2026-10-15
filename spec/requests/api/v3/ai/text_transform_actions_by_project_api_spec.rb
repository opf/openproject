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

RSpec.describe API::V3::AI::TextTransformActionsByProjectAPI,
               with_flag: { ai_text_transform_actions: true },
               with_settings: { ai_text_transform_actions_enabled: true } do
  include API::V3::Utilities::PathHelper

  shared_let(:type) { create(:type) }
  shared_let(:other_type) { create(:type) }
  shared_let(:disabled_type) { create(:type) }
  shared_let(:project) { create(:project, types: [type, other_type]) }

  shared_let(:everywhere_action) { create(:ai_text_transform_action, position: 3, label: "Everywhere") }
  shared_let(:all_types_action) do
    create(:ai_text_transform_action, position: 1, label: "All types", usage_scope: "all_work_package_types")
  end
  shared_let(:matching_type_action) do
    create(:ai_text_transform_action, position: 2, label: "Matching type",
                                      usage_scope: "specific_work_package_types", types: [type])
  end
  shared_let(:other_type_action) do
    create(:ai_text_transform_action, usage_scope: "specific_work_package_types", types: [other_type])
  end
  shared_let(:inactive_action) { create(:ai_text_transform_action, active: false) }

  let(:permissions) { %i[view_work_packages add_work_packages] }
  let(:gateway) { AI::TextTransforms::FakeGateway.new }
  let(:path) { api_v3_paths.ai_text_transform_actions_by_project(project.id, type_id: type.id) }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  before do
    allow(AI::TextTransforms::Gateway).to receive(:build).and_return(gateway)

    get path
  end

  describe "GET /api/v3/projects/:id/ai_text_transform_actions" do
    context "with add permission" do
      it_behaves_like "API V3 collection response", 3, 3, "AITextTransformAction" do
        let(:elements) { [all_types_action, matching_type_action, everywhere_action] }
      end

      it "links to itself" do
        expect(last_response.body).to be_json_eql(path.to_json).at_path("_links/self/href")
      end
    end

    context "when the feature flag is off", with_flag: { ai_text_transform_actions: false } do
      it_behaves_like "API V3 collection response", 0, 0, "AITextTransformAction"
    end

    context "when the assistant setting is off", with_settings: { ai_text_transform_actions_enabled: false } do
      it_behaves_like "API V3 collection response", 0, 0, "AITextTransformAction"
    end

    context "when the gateway is not ready" do
      let(:gateway) { AI::TextTransforms::FakeGateway.new(ready: false) }

      it_behaves_like "API V3 collection response", 0, 0, "AITextTransformAction"
    end

    context "without add permission" do
      let(:permissions) { %i[view_work_packages] }

      it_behaves_like "unauthorized access"
    end

    context "without typeId" do
      let(:path) { "#{api_v3_paths.project(project.id)}/ai_text_transform_actions" }

      it "answers bad request" do
        expect(last_response).to have_http_status(:bad_request)
      end
    end

    context "for a type not enabled in the project" do
      let(:path) { api_v3_paths.ai_text_transform_actions_by_project(project.id, type_id: disabled_type.id) }

      it_behaves_like "not found"
    end

    context "for an invisible project" do
      let(:path) { api_v3_paths.ai_text_transform_actions_by_project(create(:project).id, type_id: type.id) }

      it_behaves_like "not found"
    end
  end
end
