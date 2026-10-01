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

RSpec.describe API::V3::CostEntries::CostEntryRepresenter do
  include API::V3::Utilities::PathHelper

  let(:current_user) { build_stubbed(:user) }
  let(:workspace) { build_stubbed(:project) }
  let(:entity) { build_stubbed(:work_package, project: workspace) }
  let(:cost_entry) { build_stubbed(:cost_entry, entity:, project: workspace) }
  let(:embed_links) { true }
  let(:work_package_visible) { true }
  let(:representer) do
    described_class.new(cost_entry, current_user:, embed_links:)
  end

  subject { representer.to_json }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project :view_work_packages, project: workspace if work_package_visible && workspace
    end
  end

  describe "_links" do
    it_behaves_like "has an untitled link" do
      let(:link) { "self" }
      let(:href) { api_v3_paths.cost_entry cost_entry.id }
    end

    it_behaves_like "has workspace linked"

    it_behaves_like "has a titled link" do
      let(:link) { "user" }
      let(:href) { api_v3_paths.user cost_entry.user_id }
      let(:title) { cost_entry.user.name }
    end

    it_behaves_like "has a titled link" do
      let(:link) { "costType" }
      let(:href) { api_v3_paths.cost_type cost_entry.cost_type.id }
      let(:title) { cost_entry.cost_type.name }
    end

    it_behaves_like "has a titled link" do
      let(:link) { "entity" }
      let(:href) { api_v3_paths.work_package cost_entry.entity.id }
      let(:title) { cost_entry.entity.subject }
    end

    context "when the work package is not visible to the user" do
      let(:work_package_visible) { false }

      it_behaves_like "has a titled link" do
        let(:link) { "entity" }
        let(:href) { API::V3::URN_UNDISCLOSED }
        let(:title) { I18n.t(:"api_v3.undisclosed.workPackage") }
      end

      it_behaves_like "has a titled link" do
        let(:link) { "workPackage" }
        let(:href) { API::V3::URN_UNDISCLOSED }
        let(:title) { I18n.t(:"api_v3.undisclosed.workPackage") }
      end

      it "does not embed the work package subject or attributes" do
        expect(subject).not_to have_json_path("_embedded/entity")
        expect(subject).not_to have_json_path("_embedded/workPackage")
      end
    end
  end

  describe "properties" do
    it "has a type" do
      expect(subject).to be_json_eql("CostEntry".to_json).at_path("_type")
    end

    it "has an id" do
      expect(subject).to be_json_eql(cost_entry.id.to_json).at_path("id")
    end

    it "has spent units" do
      expect(subject).to be_json_eql(cost_entry.units.to_json).at_path("spentUnits")
    end

    it_behaves_like "has ISO 8601 date only" do
      let(:date) { cost_entry.spent_on }
      let(:json_path) { "spentOn" }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { cost_entry.created_at }
      let(:json_path) { "createdAt" }
    end

    it_behaves_like "has UTC ISO 8601 date and time" do
      let(:date) { cost_entry.updated_at }
      let(:json_path) { "updatedAt" }
    end
  end

  describe "_embedded" do
    it_behaves_like "has workspace embedded"
  end
end
