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

RSpec.describe WorkPackages::Bulk::CopyService do
  shared_let(:user) { create(:user) }
  shared_let(:project) { create(:project) }

  shared_let(:parent) do
    create(:work_package, project:, subject: "Parent")
  end
  shared_let(:child) do
    create(:work_package, project:, subject: "Child", parent:)
  end
  shared_let(:grandchild) do
    create(:work_package, project:, subject: "Grandchild", parent: child)
  end

  let(:originals) { [parent.id, child.id, grandchild.id] }

  subject(:service_call) do
    described_class
      .new(user:, work_packages: [parent])
      .call({})
  end

  def copied_subjects
    WorkPackage.where.not(id: originals).pluck(:subject)
  end

  before do
    mock_permissions_for(user) do |mock|
      # Generous project permissions so that creating the copies succeeds.
      mock.allow_in_project(:view_work_packages,
                            :add_work_packages,
                            :edit_work_packages,
                            :manage_subtasks,
                            :assign_versions,
                            :work_package_assigned,
                            project:)
      grant_copy_permission(mock)
    end
  end

  context "when the copy permission is granted on the whole project" do
    def grant_copy_permission(mock)
      mock.allow_in_project(:copy_work_packages, project:)
    end

    it "copies the whole tree" do
      expect { service_call }.to change(WorkPackage, :count).by(3)

      expect(copied_subjects).to contain_exactly("Parent", "Child", "Grandchild")
    end
  end

  context "when the copy permission is only granted on the selected parent" do
    def grant_copy_permission(mock)
      mock.allow_in_work_package(:copy_work_packages, work_package: parent)
    end

    it "copies only the parent and omits descendants the user may not copy" do
      expect { service_call }.to change(WorkPackage, :count).by(1)

      expect(copied_subjects).to contain_exactly("Parent")
    end
  end

  context "when a descendant in the middle of the tree may not be copied" do
    def grant_copy_permission(mock)
      mock.allow_in_work_package(:copy_work_packages, work_package: parent)
      mock.allow_in_work_package(:copy_work_packages, work_package: grandchild)
    end

    it "also drops the subtree hanging below the skipped descendant" do
      expect { service_call }.to change(WorkPackage, :count).by(1)

      expect(copied_subjects).to contain_exactly("Parent")
      expect(copied_subjects).not_to include("Grandchild")
    end
  end
end
