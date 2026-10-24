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

RSpec.describe "GET api/v3/workspaces/:id/work_packages row positions", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, :with_types) }
  shared_let(:open_status) { create(:status, is_closed: false) }
  shared_let(:closed_status) { create(:closed_status) }

  shared_let(:parent) { create(:work_package, project:, subject: "C parent", status: open_status) }
  shared_let(:child) { create(:work_package, project:, subject: "A child", parent:, status: open_status) }
  shared_let(:other) { create(:work_package, project:, subject: "B other", status: open_status) }

  current_user { create(:user, member_with_permissions: { project => [:view_work_packages] }) }

  let(:params) { { showHierarchies: true, filters: "[]", sortBy: '[["subject", "asc"]]', pageSize: 20, offset: 1 } }
  let(:body) { JSON.parse(last_response.body) }

  def entry(position, parent = nil)
    { "position" => position, "parent" => parent&.id&.to_s }
  end

  before do
    get "#{api_v3_paths.work_packages_by_workspace(project.id)}?#{params.to_query}"
  end

  it "numbers the results in canonical hierarchy order" do
    expect(body["rowCount"]).to eq(3)
    expect(body["rowPositions"]).to eq(parent.id.to_s => entry(1),
                                       child.id.to_s => entry(2, parent),
                                       other.id.to_s => entry(3))
  end

  context "when paginated" do
    let(:params) { super().merge(pageSize: 2) }

    it "describes the page's rows and the ancestors they render" do
      expect(body["rowCount"]).to eq(3)
      expect(body["rowPositions"]).to eq(parent.id.to_s => entry(1),
                                         child.id.to_s => entry(2, parent),
                                         other.id.to_s => entry(3))
    end

    context "on the second page" do
      let(:params) { super().merge(offset: 2) }

      it "keeps the parent's position" do
        expect(body["rowCount"]).to eq(3)
        expect(body["rowPositions"]).to eq(parent.id.to_s => entry(1))
      end
    end
  end

  context "when the parent does not match the filters" do
    let(:params) do
      super().merge(filters: [{ subject: { operator: "~", values: ["child"] } }].to_json)
    end

    it "counts the parent as a contextual ancestor" do
      expect(body["rowCount"]).to eq(2)
      expect(body["rowPositions"]).to eq(parent.id.to_s => entry(1), child.id.to_s => entry(2, parent))
    end
  end

  context "without results" do
    let(:params) do
      super().merge(filters: [{ subject: { operator: "~", values: ["nothing matches"] } }].to_json)
    end

    it "has no rows" do
      expect(body["rowCount"]).to eq(0)
      expect(body["rowPositions"]).to eq({})
    end
  end

  context "without hierarchies" do
    let(:params) { super().merge(showHierarchies: false) }

    it "omits row positions" do
      expect(body).not_to include("rowCount", "rowPositions")
    end
  end

  context "when grouped" do
    let(:params) { super().merge(groupBy: "status", showHierarchies: false) }

    it "omits row positions" do
      expect(body).not_to include("rowCount", "rowPositions")
    end
  end

  context "with baseline timestamps", with_ee: %i[baseline_comparison] do
    let(:params) { super().merge(timestamps: "2015-01-01T00:00:00Z,PT0S") }

    it "numbers the results in canonical hierarchy order" do
      expect(body["rowCount"]).to eq(3)
      expect(body["rowPositions"]).to eq(parent.id.to_s => entry(1),
                                         child.id.to_s => entry(2, parent),
                                         other.id.to_s => entry(3))
    end

    context "when a result is no longer visible", with_settings: { cross_project_work_package_relations: true } do
      shared_let(:hidden_project) { create(:project) }
      let(:baseline) { Time.zone.parse("2015-01-01") }
      let!(:hidden) do
        create(:work_package, project:, subject: "D hidden", status: open_status, created_at: baseline - 1.day,
                              journals: { baseline - 1.day => {}, 1.day.ago => {} }).tap do |work_package|
          work_package.update_column(:project_id, hidden_project.id)
          work_package.journals.last.data.update_column(:project_id, hidden_project.id)
          work_package.update!(parent:)
        end
      end
      let(:params) do
        super().merge(filters: [{ subject: { operator: "~", values: ["hidden"] } }].to_json)
      end

      before do
        get "#{api_v3_paths.work_packages_by_workspace(project.id)}?#{params.to_query}"
      end

      it "numbers it as a root without disclosing its current parent" do
        expect(body.dig("_embedded", "elements").pluck("id")).to eq([hidden.id])
        expect(body["rowCount"]).to eq(1)
        expect(body["rowPositions"]).to eq(hidden.id.to_s => entry(1))
      end
    end
  end

  context "with more results than the metadata covers" do
    before do
      stub_const("WorkPackage::HierarchyRowPositions::MAX_RESULTS", 2)
      get "#{api_v3_paths.work_packages_by_workspace(project.id)}?#{params.to_query}"
    end

    it "omits row positions" do
      expect(body).not_to include("rowCount", "rowPositions")
    end
  end
end
