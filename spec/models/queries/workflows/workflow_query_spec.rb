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

RSpec.describe Queries::Workflows::WorkflowQuery do
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:task) { create(:type, name: "Task") }
  shared_let(:milestone) { create(:type, name: "Milestone") }
  shared_let(:phase) { create(:type, name: "Phase") }

  shared_let(:bug_base) { bug.default_variant }
  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware") }

  shared_let(:on_bug) { create(:project, name: "OnBug", types: [bug]) }
  shared_let(:on_milestone) { create(:project, name: "OnMilestone", types: [milestone]) }
  shared_let(:on_phase) { create(:project, name: "OnPhase", types: [phase]) }

  shared_let(:shared_workflow) { bug_base.workflow }
  shared_let(:phase_workflow) { phase.default_variant.workflow }

  before_all do
    [task, milestone].each do |type|
      orphaned = type.default_variant.workflow
      type.default_variant.update!(workflow: shared_workflow)
      orphaned.reload.destroy!
    end

    shared_workflow.update!(name: "Standard flow", description: "Shared across the board")
    phase_workflow.update!(name: "Phase only")
  end

  def results(&) = described_class.new.tap(&).results.to_a

  describe "the unfiltered set" do
    it "holds every named workflow" do
      expect(results { it }).to contain_exactly(shared_workflow, phase_workflow)
    end

    it "orders by name, case insensitively" do
      expect(results { it }.map(&:name)).to eq(["Phase only", "Standard flow"])
    end
  end

  describe "name filter" do
    it "matches the name, case insensitively" do
      expect(results { it.where(:name, "~", ["STANDARD"]) }).to contain_exactly(shared_workflow)
    end

    it "matches the description" do
      expect(results { it.where(:name, "~", ["across the"]) }).to contain_exactly(shared_workflow)
    end

    it "keeps workflows without a description when negated" do
      expect(results { it.where(:name, "!~", ["standard"]) }).to contain_exactly(phase_workflow)
    end
  end

  describe "type filter" do
    it "finds a workflow by a type using it" do
      expect(results { it.where(:type_id, "=", [phase.id.to_s]) }).to contain_exactly(phase_workflow)
    end

    it "finds a shared workflow by any of the types using it" do
      expect(results { it.where(:type_id, "=", [task.id.to_s]) }).to contain_exactly(shared_workflow)
      expect(results { it.where(:type_id, "=", [milestone.id.to_s]) }).to contain_exactly(shared_workflow)
    end

    it "excludes a workflow when negated" do
      expect(results { it.where(:type_id, "!", [bug.id.to_s]) }).to contain_exactly(phase_workflow)
    end
  end

  describe "project filter" do
    it "finds a workflow by a project a type using it is active in" do
      expect(results { it.where(:project_id, "=", [on_phase.id.to_s]) }).to contain_exactly(phase_workflow)
    end

    it "finds a shared workflow through any of its types" do
      expect(results { it.where(:project_id, "=", [on_milestone.id.to_s]) }).to contain_exactly(shared_workflow)
    end

    it "excludes a workflow when negated" do
      expect(results { it.where(:project_id, "!", [on_bug.id.to_s]) }).to contain_exactly(phase_workflow)
    end
  end

  describe "combining filters" do
    it "narrows to the intersection" do
      found = results do |query|
        query.where(:type_id, "=", [bug.id.to_s])
        query.where(:project_id, "=", [on_bug.id.to_s])
      end

      expect(found).to contain_exactly(shared_workflow)

      missed = results do |query|
        query.where(:type_id, "=", [bug.id.to_s])
        query.where(:project_id, "=", [on_phase.id.to_s])
      end

      expect(missed).to be_empty
    end
  end
end
