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
require Rails.root.join("db/migrate/20240620115412_add_project_attribute_roles.rb")

RSpec.describe AddProjectAttributeRoles, type: :model do
  # Silencing migration logs, since we are not interested in that during testing
  subject { ActiveRecord::Migration.suppress_messages { described_class.new.change } }

  shared_examples_for "not changing permissions" do
    it "is not changed" do
      expect { subject }.not_to change { role.reload.permissions }
    end

    it "does not adds any new permissions" do
      expect { subject }.not_to change(RolePermission, :count)
    end
  end

  shared_examples_for "migration is idempotent" do
    context "when the migration is ran twice" do
      before { subject }

      it_behaves_like "not changing permissions"
    end
  end

  shared_examples_for "adding permissions" do |new_permissions|
    it "adds the #{new_permissions} permissions for the role" do
      public_permissions = OpenProject::AccessControl.public_permissions.map(&:name)
      expect { subject }.to change { role.reload.permissions }
        .from(match_array(permissions + public_permissions))
        .to match_array(permissions + public_permissions + new_permissions)
    end

    it "adds #{new_permissions.size} new permissions" do
      expect { subject }.to change(RolePermission, :count).by(new_permissions.size)
    end
  end

  context "for a role not eligible to view_project_attributes" do
    let!(:role) do
      create(:project_role,
             add_public_permissions: false,
             permissions: %i[permission1 permission2])
    end

    it_behaves_like "not changing permissions"
    it_behaves_like "migration is idempotent"
  end

  context "for a role eligible to view_project_attributes" do
    let(:permissions) { %i[view_project permission1 permission2] }
    let!(:role) { create(:project_role, permissions:) }

    it_behaves_like "adding permissions", %i[view_project_attributes]
    it_behaves_like "migration is idempotent"
  end

  context "for a role with view_project_attributes" do
    let(:permissions) { %i[view_project_attributes view_project permission1 permission2] }
    let!(:role) { create(:project_role, permissions:) }

    it_behaves_like "not changing permissions"
    it_behaves_like "migration is idempotent"
  end

  context "for a role not eligible to edit_project_attributes" do
    let(:permissions) do
      %i[view_project_attributes permission1 permission2]
    end
    let!(:role) { create(:project_role, permissions:) }

    it_behaves_like "not changing permissions"
    it_behaves_like "migration is idempotent"
  end

  context "for a role eligible to edit_project_attributes having view_project_attributes" do
    let(:permissions) do
      %i[view_project_attributes edit_project
         view_project permission1 permission2]
    end
    let!(:role) { create(:project_role, permissions:) }

    it_behaves_like "adding permissions", %i[edit_project_attributes]
    it_behaves_like "migration is idempotent"
  end

  context "for a role eligible to edit_project_attributes not having view_project_attributes" do
    let(:permissions) do
      %i[edit_project view_project permission1 permission2]
    end
    let!(:role) { create(:project_role, permissions:) }

    it_behaves_like "adding permissions", %i[edit_project_attributes view_project_attributes]
    it_behaves_like "migration is idempotent"
  end

  context "for a role that already has the edit_project_attributes and view_project_attributes permission" do
    let(:permissions) do
      %i[edit_project_attributes view_project_attributes
         edit_project view_project permission1 permission2]
    end
    let!(:role) { create(:project_role, permissions:) }

    it_behaves_like "not changing permissions"
    it_behaves_like "migration is idempotent"
  end
end
