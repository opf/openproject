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

RSpec.describe BasicData::TypeSeeder do
  include_context "with basic seed data"

  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

  before do
    seeder.seed!
  end

  context "with some types defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        types:
        - reference: :type_task
          name: Task
          color_name: cyan-7
          enabled_in_new_projects: true
          is_in_roadmap: true
          position: 1
        - reference: :type_milestone
          name: Milestone
          color_name: grape-5
          enabled_in_new_projects: true
          is_milestone: true
          position: 2
        - reference: :type_bug
          name: Bug
          color_name: red-7
          position: 3
      SEEDING_DATA_YAML
    end

    it "creates the corresponding types with the given attributes" do
      expect(Type.count).to eq(3)
      expect(Type.find_by(name: "Task")).to have_attributes(
        is_in_roadmap: true,
        is_milestone: false,
        position: 1
      )
      expect(Type.find_by(name: "Milestone")).to have_attributes(
        is_in_roadmap: false,
        is_milestone: true,
        position: 2
      )
    end

    it "enables the base variant of the flagged types in new projects" do
      expect(Type.find_by(name: "Task").default_variant).to be_enabled_in_new_projects
      expect(Type.find_by(name: "Milestone").default_variant).to be_enabled_in_new_projects
    end

    it "leaves the base variant of unflagged types disabled in new projects" do
      expect(Type.find_by(name: "Bug").default_variant).not_to be_enabled_in_new_projects
    end

    it "references the created types" do
      expect(seed_data.find_reference(:type_task)).to eq(Type.find_by(name: "Task"))
      expect(seed_data.find_reference(:type_bug)).to eq(Type.find_by(name: "Bug"))
    end
  end
end
