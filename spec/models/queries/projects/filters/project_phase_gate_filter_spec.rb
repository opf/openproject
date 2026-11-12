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

RSpec.describe Queries::Projects::Filters::ProjectPhaseGateFilter do
  let(:phase) { build_stubbed(:project_phase_definition) }
  let(:phase_with_finish_gate) do
    build_stubbed(:project_phase_definition,
                  name: "End gated phase",
                  finish_gate: true,
                  finish_gate_name: "Finish gate")
  end
  let(:phase_with_start_gate) do
    build_stubbed(:project_phase_definition,
                  name: "Start gated phase",
                  start_gate: true,
                  start_gate_name: "Start gate")
  end
  let(:phase_with_both_gates) do
    build_stubbed(:project_phase_definition,
                  name: "Double gated phase",
                  finish_gate: true,
                  finish_gate_name: "Finish gate of two",
                  start_gate: true,
                  start_gate_name: "Start gate of two")
  end
  let(:query) { build_stubbed(:project_query) }

  let(:instance) do
    described_class.create!(name: accessor, operator: "=", context: query)
  end

  before do
    allow(Project::PhaseDefinition)
      .to receive(:all)
            .and_return([phase, phase_with_start_gate, phase_with_finish_gate, phase_with_both_gates])
  end

  describe ".create!" do
    context "for an existing start gate" do
      it "returns a filter based on the gate" do
        expect(described_class.create!(name: "project_start_gate_#{phase_with_both_gates.id}", context: query))
          .to be_a described_class
      end
    end

    context "for an existing end gate" do
      it "returns a filter based on the gate" do
        expect(described_class.create!(name: "project_finish_gate_#{phase_with_both_gates.id}", context: query))
          .to be_a described_class
      end
    end

    context "for an existing phase but without a start gate" do
      it "returns a filter based on the gate" do
        expect { described_class.create!(name: "project_start_gate_#{phase_with_finish_gate.id}", context: query) }
          .to raise_error Queries::Filters::InvalidError
      end
    end

    context "for an existing phase but without an end gate" do
      it "returns a filter based on the gate" do
        expect { described_class.create!(name: "project_finish_gate_#{phase_with_start_gate.id}", context: query) }
          .to raise_error Queries::Filters::InvalidError
      end
    end

    context "for a non existing start phase" do
      it "raise an error" do
        expect { described_class.create!(name: "project_start_gate_-1", context: query) }
          .to raise_error Queries::Filters::InvalidError
      end
    end

    context "for a non existing end phase" do
      it "raise an error" do
        expect { described_class.create!(name: "project_finish_gate_-1", context: query) }
          .to raise_error Queries::Filters::InvalidError
      end
    end
  end

  describe ".all_for" do
    it "returns filters for all life cycle steps" do
      expect(described_class.all_for)
        .to all(be_a(described_class))

      expect(described_class.all_for.map(&:human_name))
        .to contain_exactly(I18n.t("project.filters.project_phase_gate", gate: phase_with_finish_gate.finish_gate_name),
                            I18n.t("project.filters.project_phase_gate", gate: phase_with_start_gate.start_gate_name),
                            I18n.t("project.filters.project_phase_gate", gate: phase_with_both_gates.start_gate_name),
                            I18n.t("project.filters.project_phase_gate", gate: phase_with_both_gates.finish_gate_name))
    end
  end

  describe ".key" do
    it "is a regex for matching lifecycle steps" do
      expect(described_class.key)
        .to eql(/\Aproject_(?<gate>finish|start)_gate_(?<id>\d+)\z/)
    end
  end

  describe "human_name" do
    context "for a start gate" do
      let(:accessor) { "project_start_gate_#{phase_with_both_gates.id}" }

      it "is the name of the gate with a prefix" do
        expect(instance.human_name)
          .to eql I18n.t("project.filters.project_phase_gate", gate: phase_with_both_gates.start_gate_name)
      end
    end

    context "for an end gate" do
      let(:accessor) { "project_finish_gate_#{phase_with_both_gates.id}" }

      it "is the name of the gate with a prefix" do
        expect(instance.human_name)
          .to eql I18n.t("project.filters.project_phase_gate", gate: phase_with_both_gates.finish_gate_name)
      end
    end
  end

  describe "#available?" do
    let(:project) { build_stubbed(:project) }
    let(:accessor) { "project_start_gate_#{phase_with_both_gates.id}" }
    let(:user) { build_stubbed(:user) }

    current_user { user }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(*permissions, project:)
      end
    end

    context "for a user with the necessary permission" do
      let(:permissions) { %i[view_project_phases] }

      it "is true" do
        expect(instance)
          .to be_available
      end
    end

    context "for a user without the necessary permission" do
      let(:permissions) { %i[view_project] }

      it "is false" do
        expect(instance)
          .not_to be_available
      end
    end
  end

  describe "#type" do
    let(:accessor) { "project_start_gate_#{phase_with_both_gates.id}" }

    it "is :date" do
      expect(instance.type)
        .to be :date
    end
  end

  describe "#name" do
    let(:accessor) { "project_start_gate_#{phase_with_both_gates.id}" }

    it "is the accessor" do
      expect(instance.name)
        .to eql accessor.to_sym
    end
  end
end
