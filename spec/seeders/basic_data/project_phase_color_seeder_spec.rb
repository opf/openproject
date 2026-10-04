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

RSpec.describe BasicData::ProjectPhaseColorSeeder do
  include_context "with basic seed data"
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

  before do
    seeder.seed!
  end

  context "with some life cycle colors defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        project_phase_colors:
        - reference: :default_color_pm2_orange
          name: PM2 Orange
          hexcode: "#F7983A"
        - reference: :default_color_pm2_red
          name: PM2 Red
          hexcode: "#F05823"
        - reference: :default_color_pm2_purple
          name: PM2 Purple
          hexcode: "#682D91"
        - reference: :default_color_pm2_magenta
          name: PM2 Magenta
          hexcode: "#EC038A"
        - reference: :default_color_pm2_green_yellow
          name: PM2 Green Yellow
          hexcode: "#B1D13A"
      SEEDING_DATA_YAML
    end

    shared_examples "creates the life cycle color seeds" do
      it "creates the corresponding life cycle colors with the given attributes" do
        expect(Color.find_by(name: "PM2 Orange")).to have_attributes(hexcode: "#F7983A")
        expect(Color.find_by(name: "PM2 Red")).to have_attributes(hexcode: "#F05823")
        expect(Color.find_by(name: "PM2 Purple")).to have_attributes(hexcode: "#682D91")
        expect(Color.find_by(name: "PM2 Magenta")).to have_attributes(hexcode: "#EC038A")
        expect(Color.find_by(name: "PM2 Green Yellow")).to have_attributes(hexcode: "#B1D13A")
      end

      it "references the life cycle colors in the seed data" do
        color_names = data_hash["project_phase_colors"].pluck("name")
        Color.where(name: color_names).find_each do |expected_stage|
          reference = :"default_color_#{expected_stage.name.downcase.gsub(/\s+/, '_')}"
          expect(seed_data.find_reference(reference)).to eq(expected_stage)
        end
      end
    end

    it_behaves_like "creates the life cycle color seeds"

    context "when some colors already exist" do
      # Typical usecase for running the seeders after an upgrade: Some data exist from
      # previous seed runs, and new seed data is added to the configuration YML.
      before do
        Color.create!(name: "Other color", hexcode: "#F7983A")
      end

      it_behaves_like "creates the life cycle color seeds"
    end

    context "when seeding a second time" do
      subject(:second_seeder) { described_class.new(second_seed_data) }

      let(:second_seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

      it "registers existing matching life cycle colors as references in the seed data" do
        expect { second_seeder.seed! }.not_to change(Color, :count)

        # using the first seed data as the expected value
        expect(second_seed_data.find_reference(:default_color_pm2_orange))
          .to eq(seed_data.find_reference(:default_color_pm2_orange))
        expect(second_seed_data.find_reference(:default_color_pm2_red))
          .to eq(seed_data.find_reference(:default_color_pm2_red))
        expect(second_seed_data.find_reference(:default_color_pm2_purple))
          .to eq(seed_data.find_reference(:default_color_pm2_purple))
        expect(second_seed_data.find_reference(:default_color_pm2_magenta))
          .to eq(seed_data.find_reference(:default_color_pm2_magenta))
        expect(second_seed_data.find_reference(:default_color_pm2_green_yellow))
          .to eq(seed_data.find_reference(:default_color_pm2_green_yellow))
      end
    end
  end

  context "without life cycle colors defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        nothing here: ''
      SEEDING_DATA_YAML
    end

    it "creates no life cycle colors" do
      expect(Color.find_by(name: "PM2 Orange")).to be_nil
      expect(Color.find_by(name: "PM2 Red")).to be_nil
      expect(Color.find_by(name: "PM2 Purple")).to be_nil
      expect(Color.find_by(name: "PM2 Magenta")).to be_nil
      expect(Color.find_by(name: "PM2 Green Yellow")).to be_nil
    end
  end
end
