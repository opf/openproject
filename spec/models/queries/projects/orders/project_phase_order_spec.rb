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

RSpec.describe Queries::Projects::Orders::ProjectPhaseOrder do
  describe ".key" do
    it "matches key in correct format for life cycles" do
      expect(described_class.key).to match("project_phase_42")
    end

    it "doesn't match non numerical id" do
      expect(described_class.key).not_to match("project_phase_abc")
    end

    it "doesn't match with prefix" do
      expect(described_class.key).not_to match("xproject_phase__42")
    end

    it "doesn't match with suffix" do
      expect(described_class.key).not_to match("project_phase__42x")
    end
  end

  describe "#available?" do
    let!(:project_phase_def) { create(:project_phase_definition) }

    let(:instance) { described_class.new("project_phase_#{project_phase_def.id}") }

    let(:permissions) { %i(view_project_phases) }
    let(:project) { create(:project) }
    let(:user) do
      create(:user, member_with_permissions: {
               project => permissions
             })
    end

    current_user { user }

    it "allows to sort by it" do
      expect(instance).to be_available
    end

    context "without permission in any project" do
      let(:permissions) { [] }

      it "is not available" do
        expect(instance).not_to be_available
      end
    end
  end

  describe "#project_phase_definition" do
    let(:instance) { described_class.new(name) }
    let(:name) { "project_phase_#{id}" }
    let(:id) { 42 }

    before do
      allow(Project::PhaseDefinition).to receive(:find_by).with(id: id.to_s).and_return(phase_definition)
    end

    context "when project phase definition exists" do
      let(:phase_definition) { instance_double(Project::PhaseDefinition) }

      it "returns the project phase definition" do
        expect(instance.project_phase_definition).to eq(phase_definition)
      end

      it "memoizes the project phase definition" do
        2.times { instance.project_phase_definition }

        expect(Project::PhaseDefinition).to have_received(:find_by).once
      end
    end

    context "when project phase definition doesn't exist" do
      let(:phase_definition) { nil }

      it "returns the life cycle" do
        expect(instance.project_phase_definition).to be_nil
      end

      it "memoizes the life cycle" do
        2.times { instance.project_phase_definition }

        expect(Project::PhaseDefinition).to have_received(:find_by).once
      end
    end
  end
end
