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

RSpec.describe BasicData::StatusSeeder do
  include_context "with basic seed data"

  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

  before do
    seeder.seed!
  end

  context "with some statuses defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        statuses:
        - reference: :status_new
          name: New
          color_name: cyan-7
          is_closed: false
          is_default: true
          position: 1
        - reference: :status_in_progress
          name: In progress
          color_name: grape-5
          default_done_ratio: 50
          position: 2
        - reference: :status_closed
          name: Closed
          color_name: gray-3
          default_done_ratio: 100
          is_closed: true
          position: 3
      SEEDING_DATA_YAML
    end

    it "creates the corresponding statuses with the given attributes" do
      expect(Status.count).to eq(3)
      expect(Status.find_by(name: "New")).to have_attributes(
        is_closed: false,
        is_default: true,
        position: 1
      )
      expect(Status.find_by(name: "In progress")).to have_attributes(
        default_done_ratio: 50,
        position: 2
      )
      expect(Status.find_by(name: "Closed")).to have_attributes(
        is_closed: true,
        is_default: false,
        default_done_ratio: 100,
        position: 3
      )
    end

    it "sets is_closed and is_default to false if not specified" do
      expect(Status.find_by(name: "In progress")).to have_attributes(
        is_closed: false,
        is_default: false
      )
    end

    it "sets default_done_ratio to 0 if not specified" do
      expect(Status.find_by(name: "New")).to have_attributes(
        default_done_ratio: 0
      )
    end

    it "looks color_id up from its name" do
      expect(Status.find_by(name: "New")).to have_attributes(
        color_id: Color.find_by(name: "cyan-7").id
      )
    end

    it "references the status in the seed data" do
      created_status = Status.last
      expect(seed_data.find_reference(:status_closed)).to eq(created_status)
    end

    context "when seeding a second time" do
      subject(:second_seeder) { described_class.new(second_seed_data) }

      let(:second_seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

      before do
        second_seeder.seed!
      end

      it "registers existing matching statuses as references in the seed data" do
        # using the first seed data as the expected value
        expect(second_seed_data.find_reference(:status_closed))
          .to eq(seed_data.find_reference(:status_closed))
        expect(second_seed_data.find_reference(:status_new))
          .to eq(seed_data.find_reference(:status_new))
        expect(second_seed_data.find_reference(:status_in_progress))
          .to eq(seed_data.find_reference(:status_in_progress))
      end
    end
  end

  context "without statuses defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        nothing here: ''
      SEEDING_DATA_YAML
    end

    it "creates no statuses" do
      expect(Status.count).to eq(0)
    end
  end
end
