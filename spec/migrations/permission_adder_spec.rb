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
require Rails.root.join("db/migrate/migration_utils/permission_adder.rb")

RSpec.describe Migration::MigrationUtils::PermissionAdder, type: :model do # rubocop:disable RSpec/SpecFilePathFormat
  let!(:role) { create(:project_role) }
  let!(:non_member_role) { create(:non_member) }
  let!(:anonymous_role) { create(:anonymous_role) }

  let(:roles) { [role, non_member_role, anonymous_role] }

  context "with a permission without special requirements" do
    it "adds the permission to all roles" do
      expect(role.permissions).not_to include(:view_project_attributes)
      expect(non_member_role.permissions).not_to include(:view_project_attributes)
      expect(anonymous_role.permissions).not_to include(:view_project_attributes)

      described_class.add(:view_project, :view_project_attributes)
      roles.each(&:reload)

      expect(role.permissions).to include(:view_project_attributes)
      expect(non_member_role.permissions).to include(:view_project_attributes)
      expect(anonymous_role.permissions).to include(:view_project_attributes)
    end

    context "when the permission already exists in role" do
      let!(:role) { create(:project_role, permissions: [:view_project_attributes]) }

      it "does not add a permission that already exists" do
        described_class.add(:view_project, :view_project_attributes)
        role.reload

        expect(role.permissions.count(:view_project_attributes)).to eq(1)
      end
    end
  end

  context "when adding a permission that has `required: :loggedin` attribute" do
    it "does not add the permission to the anonymous role" do
      described_class.add(:view_project, :move_work_packages)
      roles.each(&:reload)

      expect(role.permissions).to include(:move_work_packages)
      expect(non_member_role.permissions).to include(:move_work_packages)
      expect(anonymous_role.permissions).not_to include(:move_work_packages)
    end
  end

  context "when adding a permission that has `required: :member` attribute" do
    it "does not add the permission to the non-member and anonymous roles" do
      described_class.add(:view_project, :archive_project)
      roles.each(&:reload)

      expect(role.permissions).to include(:archive_project)
      expect(non_member_role.permissions).not_to include(:archive_project)
      expect(anonymous_role.permissions).not_to include(:archive_project)
    end
  end

  context "when having is an array of permissions" do
    let!(:role_with_all) { create(:project_role, permissions: %i[view_project view_work_packages]) }
    let!(:role_with_partial) { create(:project_role, permissions: %i[view_project]) }
    let!(:role_with_none) { create(:project_role) }

    it "only adds the permission to roles that have ALL of the having permissions" do
      described_class.add(%i[view_project view_work_packages], :view_project_attributes)

      expect(role_with_all.reload.permissions).to include(:view_project_attributes)
      expect(role_with_partial.reload.permissions).not_to include(:view_project_attributes)
      expect(role_with_none.reload.permissions).not_to include(:view_project_attributes)
    end
  end

  context "with a permission that does not exist" do
    it "results in a no-op" do
      result = nil
      expect { result = described_class.add(:view_project, :non_existent_permission) }.not_to raise_error
      expect(result).to be_nil

      roles.each(&:reload)

      expect(role.permissions).not_to include(:non_existent_permission)
      expect(non_member_role.permissions).not_to include(:non_existent_permission)
      expect(anonymous_role.permissions).not_to include(:non_existent_permission)
    end
  end
end
