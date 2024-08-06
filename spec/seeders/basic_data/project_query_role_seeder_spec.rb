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

RSpec.describe BasicData::ProjectQueryRoleSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { Source::SeedData.new(data_hash) }

  before do
    seeder.seed!
  end

  context "with some project query roles defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        project_query_roles:
          - reference: :default_role_project_query_view
            name: Project query viewer
            position: 10
            builtin: :project_query_view
            permissions:
              - :view_project_query

          - reference: :default_role_project_query_edit
            name: Project query editor
            position: 11
            builtin: :project_query_edit
            permissions:
              - :view_project_query
              - :edit_project_query
      SEEDING_DATA_YAML
    end

    it "creates the corresponding project query roles with the given attributes", :aggregate_failures do
      expect(ProjectQueryRole.count).to eq(2)
      expect(ProjectQueryRole.find_by(builtin: Role::BUILTIN_PROJECT_QUERY_VIEW)).to have_attributes(
        permissions: %i[view_project_query]
      )
      expect(ProjectQueryRole.find_by(builtin: Role::BUILTIN_PROJECT_QUERY_EDIT)).to have_attributes(
        permissions: %i[view_project_query edit_project_query]
      )
    end

    it "references the role in the seed data" do
      role = ProjectQueryRole.find_by(builtin: Role::BUILTIN_PROJECT_QUERY_VIEW)
      expect(seed_data.find_reference(:default_role_project_query_view)).to eq(role)
    end
  end

  context "with permissions: :all_assignable_permissions" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        project_query_roles:
            - name: All Project Query Permissions
              permissions: :all_assignable_permissions
      SEEDING_DATA_YAML
    end

    it "gives all assignable permissions to the role" do
      role = ProjectQueryRole.find_by(name: "All Project Query Permissions")
      expected_roles = Roles::CreateContract.new(ProjectQueryRole.new, nil).assignable_permissions.map { _1.name.to_sym }
      expect(role.permissions).to match_array(expected_roles)
    end
  end
end
