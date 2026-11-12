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

RSpec.describe DemoData::ProjectPhaseSeeder do
  include_context "with basic seed data"

  let!(:admin) { create(:admin) }
  let!(:project) { create(:project) }
  let(:full_seed_data) { Source::SeedDataLoader.get_data(only: %w[project_phases project_phase_colors]) }

  subject(:seeder) { described_class.new(project, project_seed_data) }

  before do
    # Seed the phase definitions and colors that the seeder will reference
    BasicData::ProjectPhaseColorSeeder.new(full_seed_data).seed!
    BasicData::ProjectPhaseDefinitionSeeder.new(full_seed_data).seed!

    # Make the references available to our test seed data
    %i[default_project_phase_initiating default_project_phase_planning
       default_project_phase_executing default_project_phase_closing].each do |ref|
      if definition = full_seed_data.find_reference(ref)
        project_seed_data.store_reference(ref, definition)
      end
    end
  end

  describe "#seed!" do
    context "with project_phases defined in seed data" do
      let(:project_seed_data) do
        data_hash = YAML.load <<~SEEDING_DATA_YAML
          project_phases:
            - definition: :default_project_phase_initiating
              duration: 5
            - definition: :default_project_phase_planning
              duration: 3
            - definition: :default_project_phase_executing
              duration: 8
        SEEDING_DATA_YAML

        Source::SeedData.new(data_hash)
      end

      it "activates the specified phases" do
        expect { seeder.seed! }
          .to change { project.phases.active.count }.from(0).to(3)

        phase_names = project.phases.joins(:definition).pluck("project_phase_definitions.name")
        expect(phase_names).to match_array(%w[Initiating Planning Executing])
      end

      it "sets durations and schedules from today" do
        seeder.seed!

        initiating = project.phases.joins(:definition).find_by(project_phase_definitions: { name: "Initiating" })
        planning = project.phases.joins(:definition).find_by(project_phase_definitions: { name: "Planning" })
        executing = project.phases.joins(:definition).find_by(project_phase_definitions: { name: "Executing" })

        expect(initiating.duration).to eq 5
        expect(planning.duration).to eq 3
        expect(executing.duration).to eq 8

        expect(initiating.start_date).to eq Date.current
        expect(planning.start_date).to be > initiating.finish_date
        expect(executing.start_date).to be > planning.finish_date
      end

      it "wraps operations in a transaction" do
        # Mock the activation service to raise an error
        allow(ProjectPhases::ActivationService).to receive(:new).and_raise(StandardError, "Test error")

        expect { seeder.seed! }.to raise_error(StandardError, "Test error")
        expect(project.phases.count).to eq 0 # Should be rolled back
      end
    end

    context "without project_phases in seed data" do
      let(:project_seed_data) { Source::SeedData.new({}) }

      it "does not create any phases" do
        expect { seeder.seed! }
          .not_to change { project.phases.count }
      end
    end

    context "when project already has phases" do
      let(:project_seed_data) do
        data_hash = YAML.load <<~SEEDING_DATA_YAML
          project_phases:
            - definition: :default_project_phase_initiating
              duration: 5
        SEEDING_DATA_YAML

        Source::SeedData.new(data_hash)
      end

      before do
        definition = full_seed_data.find_reference(:default_project_phase_initiating)
        project.phases.create!(definition: definition, active: true, duration: 10)
      end

      it "does not modify existing phases" do
        existing_phase = project.phases.first
        original_attributes = existing_phase.attributes.dup

        expect { seeder.seed! }
          .not_to change { project.phases.count }

        expect(existing_phase.reload.attributes).to eq(original_attributes)
      end
    end

    context "with unknown phase references in seed data" do
      let(:project_seed_data) do
        data_hash = YAML.load <<~SEEDING_DATA_YAML
          project_phases:
            - definition: :nonexistent_phase_reference
              duration: 5
            - definition: :default_project_phase_initiating
              duration: 3
        SEEDING_DATA_YAML

        Source::SeedData.new(data_hash)
      end

      it "raises an error for unknown references" do
        expect { seeder.seed! }
          .to raise_error(/Nothing registered with reference :nonexistent_phase_reference/)
      end
    end
  end
end
