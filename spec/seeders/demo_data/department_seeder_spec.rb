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

RSpec.describe DemoData::DepartmentSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { Source::SeedData.new(data_hash) }

  let(:data_hash) do
    YAML.load <<~SEEDING_DATA_YAML
      departments:
      - name: Marketing & Communications
        reference: :marketing
        members:
          - reference: :marko_marketing
            firstname: Marko
            lastname: Marketing
            job_title: Marketing Manager
            spoken_languages: [English, German]
            key_skills: [Public Speaking]
            job_start_date: "2021-03-01"
      - name: Public Relations
        reference: :public_relations
        parent: :marketing
        members:
          - reference: :petra_press
            firstname: Petra
            lastname: Press
    SEEDING_DATA_YAML
  end

  # UserCustomFieldsSeeder runs earlier in the demo data and creates these.
  shared_let(:job_title_field) do
    create(:user_custom_field, :list, name: "Job title", possible_values: ["Marketing Manager", "Software Developer"])
  end
  shared_let(:languages_field) do
    create(:user_custom_field, :multi_list, name: "Spoken languages", possible_values: %w[English German French])
  end
  shared_let(:skills_field) do
    create(:user_custom_field, :multi_list, name: "Key skills", possible_values: ["Public Speaking", "DevOps"])
  end
  shared_let(:start_date_field) { create(:user_custom_field, :date, name: "Job start date") }

  # `Groups::AddUsersService` runs under an admin (`Seeder#admin_user`).
  before { create(:admin) }

  it "creates a root department as an organizational unit with the given name" do
    seeder.seed!

    root = seed_data.find_reference(:marketing)
    expect(root).to have_attributes(lastname: "Marketing & Communications", organizational_unit: true)
    expect(root.parent).to be_nil
  end

  it "creates a child department nested under its parent" do
    seeder.seed!

    root = seed_data.find_reference(:marketing)
    child = seed_data.find_reference(:public_relations)

    expect(child).to have_attributes(lastname: "Public Relations", organizational_unit: true)
    expect(child.parent).to eq(root)
    expect(root.children).to include(child)
  end

  it "creates the member users with a derived login and mail and adds them to their department" do
    seeder.seed!

    marko = seed_data.find_reference(:marko_marketing)
    expect(marko).to have_attributes(
      firstname: "Marko",
      lastname: "Marketing",
      login: "marko.marketing",
      mail: "marko.marketing@example.com",
      status: "active"
    )

    expect(seed_data.find_reference(:marketing).users).to include(marko)
    expect(seed_data.find_reference(:public_relations).users)
      .to include(seed_data.find_reference(:petra_press))
  end

  it "assigns the curated user custom field values to the member" do
    seeder.seed!

    marko = seed_data.find_reference(:marko_marketing).reload

    expect(marko.typed_custom_value_for(job_title_field)).to eq("Marketing Manager")
    expect(marko.typed_custom_value_for(languages_field)).to contain_exactly("English", "German")
    expect(marko.typed_custom_value_for(skills_field)).to contain_exactly("Public Speaking")
    expect(marko.typed_custom_value_for(start_date_field)).to eq(Date.new(2021, 3, 1))
  end

  it "persists no custom values for members without curated values" do
    seeder.seed!

    petra = seed_data.find_reference(:petra_press).reload

    expect(petra.custom_values).to be_empty
  end

  it "is not applicable once an organizational unit already exists" do
    create(:department)

    expect(seeder).not_to be_applicable
  end
end
