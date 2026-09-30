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

RSpec.describe BasicData::ProjectPhaseDefinitionSeeder do
  include_context "with basic seed data"
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

  before do
    seeder.seed!
  end

  context "with some life cycles defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        project_phases:
        - reference: :default_project_phase_a
          name: A
          color_name: :default_color_pm2_orange
        - reference: :default_project_phase_b
          name: B
          color_name: :default_color_pm2_red
          start_gate: Ready for B
        - reference: :default_project_phase_c
          name: C
          color_name: :default_color_pm2_magenta
          start_gate: Ready for C
      SEEDING_DATA_YAML
    end

    it "creates the corresponding life cycles with the given attributes" do
      expect(Project::PhaseDefinition.count).to eq(3)
      expect(Project::PhaseDefinition.find_by(name: "A")).to have_attributes(
        color: have_attributes(name: "PM2 Orange")
      )
      expect(Project::PhaseDefinition.find_by(name: "B")).to have_attributes(
        color: have_attributes(name: "PM2 Red")
      )
      expect(Project::PhaseDefinition.find_by(name: "C")).to have_attributes(
        color: have_attributes(name: "PM2 Magenta")
      )
    end

    it "references the phases in the seed data" do
      Project::PhaseDefinition.find_each do |expected_stage|
        reference = :"default_project_phase_#{expected_stage.name.downcase.gsub(/\s+/, '_')}"
        expect(seed_data.find_reference(reference)).to eq(expected_stage)
      end
    end

    context "when seeding a second time" do
      subject(:second_seeder) { described_class.new(second_seed_data) }

      let(:second_seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

      before do
        second_seeder.seed!
      end

      it "registers existing matching life cycles as references in the seed data" do
        # using the first seed data as the expected value
        expect(second_seed_data.find_reference(:default_project_phase_a))
          .to eq(seed_data.find_reference(:default_project_phase_a))
        expect(second_seed_data.find_reference(:default_project_phase_b))
          .to eq(seed_data.find_reference(:default_project_phase_b))
        expect(second_seed_data.find_reference(:default_project_phase_c))
          .to eq(seed_data.find_reference(:default_project_phase_c))
      end
    end
  end

  context "without phases defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        nothing here: ''
      SEEDING_DATA_YAML
    end

    it "creates no life cycles" do
      expect(Project::PhaseDefinition.count).to eq(0)
    end
  end
end
