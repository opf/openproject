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

RSpec.describe Query::Results, "project phase filter" do
  shared_let(:definition) { create(:project_phase_definition) }
  shared_let(:project) { create(:project) }
  shared_let(:phase) { create(:project_phase, project:, definition:, active: true) }
  shared_let(:wp_with_phase) { create(:work_package, project:, project_phase_definition: definition) }
  shared_let(:wp_without_phase) { create(:work_package, project:) }

  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages view_project_phases] })
  end

  current_user { user }

  def build_query(filter_values: [definition.id.to_s])
    build(:query,
          user:,
          project:,
          show_hierarchies: false,
          column_names: %i[id subject]).tap do |q|
      q.add_filter("project_phase_definition_id", "=", filter_values)
    end
  end

  context "with semantic identifiers enabled",
          with_settings: { work_packages_identifier: "semantic" } do
    it "does not raise a SQL error for a non-admin user (Regression: explicit projects join removal)" do
      expect { described_class.new(build_query).work_packages.to_a }.not_to raise_error
    end

    it "returns only the work package with the matching phase" do
      results = described_class.new(build_query).work_packages
      expect(results).to include(wp_with_phase)
      expect(results).not_to include(wp_without_phase)
    end
  end

  context "with classic identifiers enabled",
          with_settings: { work_packages_identifier: "classic" } do
    it "does not raise a SQL error" do
      expect { described_class.new(build_query).work_packages.to_a }.not_to raise_error
    end

    it "returns only the work package with the matching phase" do
      results = described_class.new(build_query).work_packages
      expect(results).to include(wp_with_phase)
      expect(results).not_to include(wp_without_phase)
    end
  end

  describe "filter operators across phase visibility states" do
    let(:other_definition) { create(:project_phase_definition) }
    let!(:other_phase) { create(:project_phase, project:, definition: other_definition, active: true) }
    let!(:wp_with_other_phase) do
      create(:work_package, project:, project_phase_definition: other_definition)
    end
    let(:other_project) { create(:project, name: "Another project") }
    let!(:other_project_phase) do
      create(:project_phase, project: other_project, definition:, active: other_project_phase_active)
    end
    let!(:wp_without_phase_in_other_project) { create(:work_package, project: other_project) }
    let!(:wp_with_phase_in_other_project) do
      create(:work_package, project: other_project, project_phase_definition: definition)
    end
    let(:other_project_phase_active) { true }
    let(:query_project) { project }
    let(:other_project_permissions) { %i[view_work_packages view_project_phases] }
    let(:user) do
      create(:user,
             member_with_permissions: {
               project => %i[view_work_packages view_project_phases],
               other_project => other_project_permissions
             })
    end

    def results_for(operator, values = nil)
      query = build(:query, user:, project: query_project&.reload, show_hierarchies: false)
      query.filters.clear
      query.add_filter("project_phase_definition_id", operator, values)
      described_class.new(query).work_packages.to_a
    end

    it "applies every operator to active phases in one project" do
      expect(results_for("=", [definition.id.to_s])).to contain_exactly(wp_with_phase)
      expect(results_for("=", [definition.id.to_s, other_definition.id.to_s]))
        .to contain_exactly(wp_with_phase, wp_with_other_phase)
      expect(results_for("!", [other_definition.id.to_s])).to contain_exactly(wp_with_phase, wp_without_phase)
      expect(results_for("*")).to contain_exactly(wp_with_phase, wp_with_other_phase)
      expect(results_for("!*")).to contain_exactly(wp_without_phase)
    end

    context "with one inactive phase" do
      before { phase.update!(active: false) }

      it "treats the inactive phase as unassigned for every operator" do
        values = [definition.id.to_s, other_definition.id.to_s]

        expect(results_for("=", values)).to contain_exactly(wp_with_other_phase)
        expect(results_for("!", values)).to contain_exactly(wp_with_phase, wp_without_phase)
        expect(results_for("*")).to contain_exactly(wp_with_other_phase)
        expect(results_for("!*")).to contain_exactly(wp_with_phase, wp_without_phase)
      end
    end

    context "with a global query and an inactive phase in another project" do
      let(:query_project) { nil }
      let(:other_project_phase_active) { false }

      it "applies every operator using each project's active phases" do
        expect(results_for("=", [definition.id.to_s])).to contain_exactly(wp_with_phase)
        expect(results_for("!", [definition.id.to_s]))
          .to contain_exactly(wp_without_phase, wp_with_other_phase,
                              wp_without_phase_in_other_project, wp_with_phase_in_other_project)
        expect(results_for("*")).to contain_exactly(wp_with_phase, wp_with_other_phase)
        expect(results_for("!*")).to contain_exactly(wp_without_phase,
                                                     wp_without_phase_in_other_project,
                                                     wp_with_phase_in_other_project)
      end
    end

    context "with a global query and no phase permission in another project" do
      let(:query_project) { nil }
      let(:other_project_permissions) { %i[view_work_packages] }

      it "treats the unviewable phase as unassigned for every operator" do
        expect(results_for("=", [definition.id.to_s])).to contain_exactly(wp_with_phase)
        expect(results_for("!", [definition.id.to_s]))
          .to contain_exactly(wp_without_phase, wp_with_other_phase,
                              wp_without_phase_in_other_project, wp_with_phase_in_other_project)
        expect(results_for("*")).to contain_exactly(wp_with_phase, wp_with_other_phase)
        expect(results_for("!*")).to contain_exactly(wp_without_phase,
                                                     wp_without_phase_in_other_project,
                                                     wp_with_phase_in_other_project)
      end
    end
  end
end
