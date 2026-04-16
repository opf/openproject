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

RSpec.describe WorkPackage do
  describe ".update_versions_from_sharing_change" do
    let(:project_a) { create(:project) }
    let(:project_b) { create(:project) }
    let(:version) { create(:version, project: project_a, sharing: "system") }
    let(:work_package) { create(:work_package, project: project_b, version:) }

    describe "cleaning up target_versions" do
      before do
        WorkPackageAssociatedVersion.create!(work_package:, version:, kind: "target")
      end

      it "removes target_versions referencing the unshared version" do
        version.update_column(:sharing, "none")

        described_class.update_versions_from_sharing_change(version)

        work_package.reload
        expect(work_package.version_id).to be_nil
        expect(work_package.target_versions).to be_empty
      end
    end

    describe "preserving still-shared associated versions" do
      let!(:local_version) { create(:version, project: project_b) }

      before do
        WorkPackageAssociatedVersion.create!(work_package:, version:, kind: "target")
        WorkPackageAssociatedVersion.create!(work_package:, version: local_version, kind: "target")
      end

      it "only removes the unshared version, keeping the still-shared one" do
        version.update_column(:sharing, "none")

        described_class.update_versions_from_sharing_change(version)

        work_package.reload
        expect(work_package.version_id).to be_nil
        expect(work_package.target_versions).to contain_exactly(local_version)
      end
    end
  end

  describe ".update_versions_from_hierarchy_change" do
    let(:parent_project) { create(:project) }
    let(:child_project) { create(:project, parent: parent_project) }
    let(:other_project) { create(:project) }
    let(:version) { create(:version, project: parent_project, sharing: "tree") }
    let(:work_package) { create(:work_package, project: child_project, version:) }

    describe "cleaning up associated versions after project move" do
      before do
        WorkPackageAssociatedVersion.create!(work_package:, version:, kind: "target")
      end

      it "removes associated versions when project moves out of hierarchy" do
        # Move child_project out of parent_project's tree using nested set API
        child_project.move_to_child_of(other_project)

        described_class.update_versions_from_hierarchy_change(child_project)

        work_package.reload
        expect(work_package.version_id).to be_nil
        expect(work_package.target_versions).to be_empty
      end
    end
  end
end
