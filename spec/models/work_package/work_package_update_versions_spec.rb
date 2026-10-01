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

RSpec.describe WorkPackage, ".update_versions keeping target_versions consistent" do
  let(:parent_project) { create(:project) }
  let!(:child_project) { create(:project, parent: parent_project) }
  let(:shared_version) { create(:version, project: parent_project, sharing: "descendants") }
  let!(:work_package) { create(:work_package, project: child_project, version: shared_version) }

  def target_version_ids(work_package)
    work_package.work_package_versions.where(kind: "target").pluck(:version_id)
  end

  it "drops the target version when the version stops being shared" do
    expect(target_version_ids(work_package)).to contain_exactly(shared_version.id)

    shared_version.update!(sharing: "none")
    described_class.update_versions_from_sharing_change(shared_version)

    work_package.reload
    expect(target_version_ids(work_package)).to be_empty
  end

  it "drops the target version when the project moves out of the sharing hierarchy" do
    expect(target_version_ids(work_package)).to contain_exactly(shared_version.id)

    child_project.update!(parent: nil)
    described_class.update_versions_from_hierarchy_change(child_project)

    work_package.reload
    expect(target_version_ids(work_package)).to be_empty
  end

  it "drops an unshared target version beyond the first, keeping the others" do
    own_version = create(:version, project: child_project)
    work_package.work_package_versions.create!(version: own_version, kind: "target")

    shared_version.update!(sharing: "none")
    described_class.update_versions_from_sharing_change(shared_version)

    work_package.reload
    expect(target_version_ids(work_package)).to contain_exactly(own_version.id)
  end

  it "drops an unshared observed_in version" do
    work_package.work_package_versions.create!(version: shared_version, kind: "observed_in")

    shared_version.update!(sharing: "none")
    described_class.update_versions_from_sharing_change(shared_version)

    work_package.reload
    expect(work_package.work_package_versions.where(kind: "observed_in")).to be_empty
    expect(target_version_ids(work_package)).to be_empty
  end

  it "excludes systemwide-shared versions" do
    shared_version.update!(sharing: "system")
    described_class.update_versions_from_sharing_change(shared_version)

    work_package.reload
    expect(target_version_ids(work_package)).to contain_exactly(shared_version.id)
  end
end
