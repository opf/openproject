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

RSpec.describe BasicData::WorkPackageRoleSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { Source::SeedData.new(data_hash) }

  before do
    seeder.seed!
  end

  context "with some work package roles defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        work_package_roles:
          - reference: :role_work_package_edit
            name: Edit work package
            position: 3
            builtin: :work_package_editor
            permissions:
            - :become_assignee
            - :log_time
          - reference: :role_work_package_comment
            name: Comment work package
            builtin: :work_package_commenter
            position: 5
            permissions:
            - :add_comment
          - reference: :role_work_package_view
            name: View work package
            builtin: :work_package_viewer
            position: 6
            permissions:
            - :view_work_packages
      SEEDING_DATA_YAML
    end

    it "creates the corresponding work package roles with the given attributes", :aggregate_failures do
      expect(WorkPackageRole.count)
        .to eq(3)
      expect(WorkPackageRole.find_by(name: "Edit work package"))
        .to have_attributes(
          builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR,
          permissions: %i[become_assignee log_time]
        )
      expect(WorkPackageRole.find_by(name: "Comment work package"))
        .to have_attributes(
          builtin: Role::BUILTIN_WORK_PACKAGE_COMMENTER,
          permissions: %i[add_comment]
        )
      expect(WorkPackageRole.find_by(name: "View work package"))
        .to have_attributes(
          builtin: Role::BUILTIN_WORK_PACKAGE_VIEWER,
          permissions: %i[view_work_packages]
        )
    end

    it "references the role in the seed data" do
      role = WorkPackageRole.find_by(name: "Comment work package")
      expect(seed_data.find_reference(:role_work_package_comment)).to eq(role)
    end
  end

  context "with permissions: :all_assignable_permissions" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        work_package_roles:
          - reference: :role_work_package_edit
            name: Edit work package
            permissions: :all_assignable_permissions
      SEEDING_DATA_YAML
    end

    it "gives all assignable permissions to the role" do
      expect(Role.find_by(name: "Edit work package").permissions)
        .to match_array(Roles::CreateContract.new(WorkPackageRole.new, nil)
                                             .assignable_permissions.map { _1.name.to_sym })
    end
  end

  context "with some permissions added and removed by modules in a modules_permissions section" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        work_package_roles:
          - reference: :role_work_package_edit
            name: Edit work package
            position: 5
            permissions:
            - :view_movies
            - :eat_cheese
        modules_permissions:
          ebooks:
          - role: :role_work_package_edit
            add:
            - :read_ebooks
            - :rate_ebooks
          music:
          - role: :role_work_package_edit
            add:
            - :play_music
            - :add_song
          health_control:
          - role: :role_work_package_edit
            remove:
            - :eat_cheese
      SEEDING_DATA_YAML
    end

    it "applies the permissions as specified" do
      expect(Role.find_by(name: "Edit work package").permissions)
        .to match_array(
          %i[
            view_movies
            read_ebooks
            rate_ebooks
            play_music
            add_song
          ]
        )
    end
  end
end
