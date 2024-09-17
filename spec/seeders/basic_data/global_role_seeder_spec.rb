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

RSpec.describe BasicData::GlobalRoleSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { Source::SeedData.new(data_hash) }

  before do
    seeder.seed!
  end

  context "with some global roles defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        global_roles:
          - reference: :role_staff_manager
            name: Staff manager
            permissions:
            - :hire_people
            - :give_feedback
      SEEDING_DATA_YAML
    end

    it "creates the corresponding global roles with the given attributes" do
      expect(GlobalRole.count).to eq(1)
      expect(GlobalRole.find_by(name: "Staff manager")).to have_attributes(
        builtin: Role::NON_BUILTIN,
        permissions: %i[hire_people give_feedback]
      )
    end

    it "references the role in the seed data" do
      role = GlobalRole.find_by(name: "Staff manager")
      expect(seed_data.find_reference(:role_staff_manager)).to eq(role)
    end
  end

  context "with permissions: :all_assignable_permissions" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        global_roles:
          - reference: :role_project_admin
            name: Project admin
            global: true
            position: 1
            permissions: :all_assignable_permissions
      SEEDING_DATA_YAML
    end

    it "gives all assignable permissions to the role" do
      expect(GlobalRole.find_by(name: "Project admin").permissions)
        .to match_array(Roles::CreateContract.new(GlobalRole.new, nil).assignable_permissions.map { _1.name.to_sym })
    end
  end
end
