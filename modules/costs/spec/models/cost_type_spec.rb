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

require_relative "../spec_helper"

RSpec.describe CostType do
  let(:cost_type) do
    described_class.new name: "ct1",
                        unit: "singular",
                        unit_plural: "plural"
  end

  describe "class" do
    describe "active" do
      describe "WHEN a CostType instance is deleted" do
        before do
          cost_type.deleted_at = Time.zone.now
          cost_type.save!
        end

        it { expect(described_class.active.size).to eq(0) }
      end

      describe "WHEN a CostType instance is not deleted" do
        before do
          cost_type.save!
        end

        it { expect(described_class.active.size).to eq(1) }
        it { expect(described_class.active[0]).to eq(cost_type) }
      end
    end
  end

  describe ".available_for_project" do
    let(:project) { create(:project) }
    let(:other_project) { create(:project) }
    let!(:global_ct) { create(:cost_type, for_all_projects: true) }
    let!(:scoped_ct) { create(:cost_type, for_all_projects: false) }
    let!(:unrelated_ct) { create(:cost_type, for_all_projects: false) }

    before do
      CostTypesProject.create!(cost_type: scoped_ct, project: project)
      CostTypesProject.create!(cost_type: unrelated_ct, project: other_project)
    end

    it "returns global cost types plus those explicitly mapped to the project" do
      expect(described_class.available_for_project(project)).to contain_exactly(global_ct, scoped_ct)
    end

    it "accepts a project_id integer too" do
      expect(described_class.available_for_project(project.id)).to contain_exactly(global_ct, scoped_ct)
    end
  end

  describe ".default_for_project" do
    let(:project) { create(:project) }

    context "when the global default is available in the project" do
      let!(:default_ct) { create(:cost_type, for_all_projects: true, default: true) }
      let!(:_other) { create(:cost_type, for_all_projects: true) }

      it "returns the default" do
        expect(described_class.default_for_project(project)).to eq(default_ct)
      end
    end

    context "when no default cost type is available in the project" do
      let!(:default_ct) { create(:cost_type, for_all_projects: false, default: true) }
      let!(:available) { create(:cost_type, for_all_projects: true) }

      it "falls back to the first available cost type" do
        expect(described_class.default_for_project(project)).to eq(available)
      end
    end

    context "when no cost type is available in the project" do
      let!(:_unrelated) { create(:cost_type, for_all_projects: false) }

      it "returns nil" do
        expect(described_class.default_for_project(project)).to be_nil
      end
    end
  end
end
