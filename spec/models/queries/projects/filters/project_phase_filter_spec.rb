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

RSpec.describe Queries::Projects::Filters::ProjectPhaseFilter do
  let(:phase) { build_stubbed(:project_phase_definition) }
  let(:phase_with_finish_gate) { build_stubbed(:project_phase_definition, finish_gate: true) }
  let(:phase_with_start_gate) { build_stubbed(:project_phase_definition, start_gate: true) }
  let(:query) { build_stubbed(:project_query) }

  let(:instance) do
    described_class.create!(name: accessor, operator: "=", context: query)
  end

  before do
    allow(Project::PhaseDefinition)
      .to receive(:all)
            .and_return([phase, phase_with_finish_gate, phase_with_start_gate])
  end

  describe ".create!" do
    context "for an existing phase" do
      it "returns a filter based on the phase" do
        expect(described_class.create!(name: "project_phase_#{phase.id}", context: query))
          .to be_a described_class
      end
    end

    context "for a non existing phase" do
      it "raise an error" do
        expect { described_class.create!(name: "project_phase_-1", context: query) }
          .to raise_error Queries::Filters::InvalidError
      end
    end
  end

  describe ".all_for" do
    it "returns filters for all life cycle steps" do
      expect(described_class.all_for)
        .to all(be_a(described_class))

      expect(described_class.all_for.map(&:human_name))
        .to contain_exactly(I18n.t("project.filters.project_phase", phase: phase.name),
                            I18n.t("project.filters.project_phase", phase: phase_with_finish_gate.name),
                            I18n.t("project.filters.project_phase", phase: phase_with_start_gate.name))
    end
  end

  describe ".key" do
    it "is a regex for matching lifecycle steps" do
      expect(described_class.key)
        .to eql(/\Aproject_phase_(?<id>\d+)\z/)
    end
  end

  describe "human_name" do
    let(:accessor) { "project_phase_#{phase.id}" }

    it "is the name of the phase with a prefix" do
      expect(instance.human_name)
        .to eql I18n.t("project.filters.project_phase", phase: phase.name)
    end
  end

  describe "#available?" do
    let(:project) { build_stubbed(:project) }
    let(:accessor) { "project_phase_#{phase.id}" }
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
    let(:accessor) { "project_phase_#{phase.id}" }

    it "is :date" do
      expect(instance.type)
        .to be :date
    end
  end

  describe "#name" do
    let(:accessor) { "project_phase_#{phase.id}" }

    it "is the accessor" do
      expect(instance.name)
        .to eql accessor.to_sym
    end
  end
end
