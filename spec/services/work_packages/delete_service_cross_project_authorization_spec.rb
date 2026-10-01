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

RSpec.describe WorkPackages::DeleteService, "integration", type: :model,
                                                           with_settings: { cross_project_work_package_relations: true } do
  let(:project_a) { create(:project_with_types) }
  let(:project_b) { create(:project_with_types) }
  let(:permissions_a) { %i[view_work_packages delete_work_packages] }
  let(:permissions_b) { %i[view_work_packages] }
  let(:role_a) { create(:project_role, permissions: permissions_a) }
  let(:role_b) { create(:project_role, permissions: permissions_b) }
  let(:user) do
    create(:user).tap do |u|
      create(:member, project: project_a, principal: u, roles: [role_a])
      create(:member, project: project_b, principal: u, roles: [role_b]) if permissions_b.any?
    end
  end

  let!(:parent) { create(:work_package, project: project_a, subject: "Parent") }
  let!(:child) { create(:work_package, project: project_b, parent:, subject: "Child") }

  subject(:call) { described_class.new(user:, model: parent).call }

  shared_examples "detaches the child" do
    it "deletes the parent" do
      expect(call).to be_success
      expect(WorkPackage).not_to exist(parent.id)
    end

    it "keeps the child without a parent" do
      call

      expect(child.reload.parent_id).to be_nil
    end

    it "records the reason as a journal cause on the child" do
      call

      expect(child.reload.journals.last.cause_type).to eq("work_package_parent_deleted")
    end

    it "does not name the deleted parent in the journal cause" do
      call

      expect(child.reload.journals.last.cause.keys).to contain_exactly("type")
    end
  end

  context "when the child is only visible to the user" do
    it_behaves_like "detaches the child"
  end

  context "when the child is in a project invisible to the user" do
    let(:permissions_b) { [] }

    it_behaves_like "detaches the child"
  end

  context "when every descendant is deletable" do
    let!(:child) { create(:work_package, project: project_a, parent:, subject: "Child") }
    let!(:grandchild) { create(:work_package, project: project_a, parent: child, subject: "Grandchild") }

    it "deletes the whole subtree" do
      expect(call).to be_success
      expect(WorkPackage).not_to exist(parent.id)
      expect(WorkPackage).not_to exist(child.id)
      expect(WorkPackage).not_to exist(grandchild.id)
    end
  end

  context "when the undeletable work package is a grandchild" do
    let!(:child) { create(:work_package, project: project_a, parent:, subject: "Child") }
    let!(:grandchild) { create(:work_package, project: project_b, parent: child, subject: "Grandchild") }

    it "deletes the parent and the child" do
      expect(call).to be_success
      expect(WorkPackage).not_to exist(parent.id)
      expect(WorkPackage).not_to exist(child.id)
    end

    it "detaches the grandchild from the deleted child" do
      call

      expect(grandchild.reload.parent_id).to be_nil
      expect(grandchild.journals.last.cause_type).to eq("work_package_parent_deleted")
    end
  end

  context "when a deletable work package hangs below an undeletable one" do
    let!(:grandchild) { create(:work_package, project: project_a, parent: child, subject: "Grandchild") }

    it "keeps the whole subtree below the detached child" do
      expect(call).to be_success
      expect(WorkPackage).not_to exist(parent.id)
      expect(child.reload.parent_id).to be_nil
      expect(grandchild.reload.parent_id).to eq(child.id)
    end
  end
end
