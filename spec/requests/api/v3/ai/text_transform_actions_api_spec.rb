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

RSpec.describe API::V3::AI::TextTransformActionsAPI,
               with_flag: { ai_text_transform_actions: true },
               with_settings: { ai_text_transform_actions_enabled: true } do
  include API::V3::Utilities::PathHelper

  shared_let(:everywhere_action) { create(:ai_text_transform_action, position: 2, label: "Everywhere") }
  shared_let(:first_action) { create(:ai_text_transform_action, position: 1, label: "First") }
  shared_let(:inactive_action) { create(:ai_text_transform_action, active: false) }
  shared_let(:type_scoped_action) { create(:ai_text_transform_action, usage_scope: "all_work_package_types") }

  let(:gateway) { AI::TextTransforms::FakeGateway.new }

  current_user { create(:user) }

  before do
    allow(AI::TextTransforms::Gateway).to receive(:build).and_return(gateway)

    get api_v3_paths.ai_text_transform_actions
  end

  describe "GET /api/v3/ai_text_transform_actions" do
    context "for a logged in user" do
      it_behaves_like "API V3 collection response", 2, 2, "AITextTransformAction" do
        let(:elements) { [first_action, everywhere_action] }
      end

      it "links to itself" do
        expect(last_response.body)
          .to be_json_eql(api_v3_paths.ai_text_transform_actions.to_json).at_path("_links/self/href")
      end

      it "omits type-scoped and inactive actions" do
        labels = JSON.parse(last_response.body).dig("_embedded", "elements").pluck("label")

        expect(labels).to eq(%w[First Everywhere])
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

    context "for an anonymous user" do
      current_user { User.anonymous }

      it_behaves_like "unauthenticated access"
    end
  end
end
