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

RSpec.describe BasicData::ProjectCustomFieldSectionSeeder do
  include_context "with basic seed data"

  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

  before do
    seeder.seed!
  end

  context "with some sections defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        project_custom_field_sections:
          - reference: :section_one
            name: Project Attributes
            position: 1
          - reference: :section_two
            name: Project Attributes Two
            position: 2
      SEEDING_DATA_YAML
    end

    it "creates the corresponding sections with the given attributes", :aggregate_failures do
      expect(ProjectCustomFieldSection.count).to eq(2)
      expect(ProjectCustomFieldSection.find_by(name: "Project Attributes"))
        .to have_attributes(position: 1)
      expect(ProjectCustomFieldSection.find_by(name: "Project Attributes Two"))
        .to have_attributes(position: 2)

      # references the section in the seed data
      created_status = ProjectCustomFieldSection.last
      expect(seed_data.find_reference(:section_two)).to eq(created_status)
    end

    context "when seeding a second time" do
      subject(:second_seeder) { described_class.new(second_seed_data) }

      let(:second_seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

      before do
        second_seeder.seed!
      end

      it "registers existing matching sections as references in the seed data" do
        # using the first seed data as the expected value
        expect(second_seed_data.find_reference(:section_one))
          .to eq(seed_data.find_reference(:section_one))
        expect(second_seed_data.find_reference(:section_two))
          .to eq(seed_data.find_reference(:section_two))
      end
    end
  end

  context "without sections defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        nothing here: ''
      SEEDING_DATA_YAML
    end

    it "creates no sections" do
      expect(ProjectCustomFieldSection.count).to eq(0)
    end
  end
end
