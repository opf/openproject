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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../../../../spec_helper"

RSpec.describe Queries::Projects::Filters::AvailableCostTypesProjectsFilter do
  let(:instance) { described_class.create!(name: described_class.key) }

  describe ".key" do
    it { expect(described_class.key).to eq(:available_cost_types_projects) }
  end

  describe "#allowed_values" do
    before { CostType.destroy_all }

    let!(:scoped_a) { create(:cost_type, for_all_projects: false, name: "Disk") }
    let!(:scoped_b) { create(:cost_type, for_all_projects: false, name: "License") }
    let!(:_global)  { create(:cost_type, for_all_projects: true, name: "Travel") }

    it "lists only non-global cost types (so filter validates even before any mapping exists)" do
      expect(instance.allowed_values).to contain_exactly(
        ["Disk", scoped_a.id],
        ["License", scoped_b.id]
      )
    end
  end

  describe "filter is registered with ProjectQuery" do
    it "is in the ProjectQuery filter registry" do
      expect(Queries::Register.filters[ProjectQuery]).to include(described_class)
    end
  end

  describe "applying the filter via ProjectQuery" do
    let(:admin) { create(:admin) }
    let!(:cost_type) { create(:cost_type, for_all_projects: false) }
    let!(:mapped_project) { create(:project) }
    let!(:unmapped_project) { create(:project) }

    before do
      login_as(admin)
      CostTypesProject.create!(cost_type:, project: mapped_project)
    end

    it "returns only projects mapped to the given cost type" do
      query = ProjectQuery.new(name: "t") do |q|
        q.where(:available_cost_types_projects, "=", [cost_type.id])
        q.select(:name)
      end

      expect(query).to be_valid
      expect(query.results.pluck(:id)).to contain_exactly(mapped_project.id)
    end

    it "returns no projects when the cost type has no mappings (and query stays valid)" do
      cost_type_without_mappings = create(:cost_type, for_all_projects: false)

      query = ProjectQuery.new(name: "t2") do |q|
        q.where(:available_cost_types_projects, "=", [cost_type_without_mappings.id])
        q.select(:name)
      end

      expect(query).to be_valid
      expect(query.results).to be_empty
    end
  end
end
