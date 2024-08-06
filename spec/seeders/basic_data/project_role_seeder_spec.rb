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

RSpec.describe BasicData::ProjectRoleSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { Source::SeedData.new(data_hash) }
  let(:public_permissions) { OpenProject::AccessControl.public_permissions.map(&:name) }

  before do
    seeder.seed!
  end

  context "with some builtin roles defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        project_roles:
          - reference: :role_non_member
            name: Non member
            builtin: :non_member
            permissions:
            - :view_status
            - :view_presentations
          - reference: :role_anonymous
            name: Anonymous
            builtin: :anonymous
            permissions:
            - :read_information
      SEEDING_DATA_YAML
    end

    it "creates the corresponding builtin roles with the given attributes" do
      expect(Role.count).to eq(2)
      expect(Role.find_by(name: "Non member")).to have_attributes(
        builtin: Role::BUILTIN_NON_MEMBER,
        permissions: %i[view_status view_presentations] + public_permissions
      )
      expect(Role.find_by(name: "Anonymous")).to have_attributes(
        builtin: Role::BUILTIN_ANONYMOUS,
        permissions: %i[read_information] + public_permissions
      )
    end

    it "references the role in the seed data" do
      role = Role.find_by(name: "Anonymous")
      expect(seed_data.find_reference(:role_anonymous)).to eq(role)
    end
  end

  context "with some non-builtin roles defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        project_roles:
          - reference: :role_member
            name: Member
            position: 5
            permissions:
            - :view_movies
            - :eat_popcorn
      SEEDING_DATA_YAML
    end

    it "creates the corresponding roles with the given attributes" do
      expect(Role.count).to eq(1)
      expect(Role.find_by(name: "Member")).to have_attributes(
        position: 5,
        builtin: Role::NON_BUILTIN,
        permissions: %i[view_movies eat_popcorn] + public_permissions
      )
    end

    it "references the role in the seed data" do
      member_role = Role.find_by(name: "Member")
      expect(seed_data.find_reference(:role_member)).to eq(member_role)
    end
  end

  context "with permissions: :all_assignable_permissions" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        project_roles:
          - reference: :role_project_admin
            name: Project admin
            position: 1
            permissions: :all_assignable_permissions
      SEEDING_DATA_YAML
    end

    it "gives all assignable permissions to the role" do
      expect(Role.find_by(name: "Project admin").permissions)
        .to match_array(Roles::CreateContract.new(Role.new, nil).assignable_permissions(keep_public: true).map { _1.name.to_sym })
    end

    it "includes the project attributes permissions to the role" do
      expect(Role.find_by(name: "Project admin").permissions)
        .to include(:view_project_attributes, :edit_project_attributes)
    end
  end

  context "with some permissions added and removed by modules in a modules_permissions section" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        project_roles:
          - reference: :role_member
            name: Member
            position: 5
            permissions:
            - :view_movies
            - :eat_popcorn
        modules_permissions:
          ebooks:
          - role: :role_member
            add:
            - :read_ebooks
            - :rate_ebooks
          music:
          - role: :role_member
            add:
            - :play_music
            - :add_song
          health_control:
          - role: :role_member
            remove:
            - :eat_popcorn
      SEEDING_DATA_YAML
    end

    it "applies the permissions as specified" do
      expect(Role.find_by(name: "Member").permissions)
        .to match_array(
          %i[
            view_movies
            read_ebooks
            rate_ebooks
            play_music
            add_song
          ] + public_permissions
        )
    end
  end
end
