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
require Rails.root.join("db/migrate/20260629134641_backfill_target_versions_from_work_package.rb")

RSpec.describe BackfillTargetVersionsFromWorkPackage, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  let(:project) { create(:project) }
  let(:version) { create(:version, project:) }
  let(:other_version) { create(:version, project:) }

  let!(:work_package_with_version) { create(:work_package, project:, version:) }
  let!(:work_package_without_version) { create(:work_package, project:, version: nil) }

  it "succeeds" do
    expect { migrate }.not_to raise_error
  end

  it "creates a target work_package_version for each work package with a version" do
    migrate

    expect(WorkPackageVersion.where(work_package: work_package_with_version).pluck(:version_id, :kind))
      .to contain_exactly([version.id, "target"])
  end

  it "does not create entries for work packages without a version" do
    migrate

    expect(WorkPackageVersion.where(work_package: work_package_without_version)).to be_empty
  end

  context "when a target work_package_version already exists" do
    let!(:existing) do
      WorkPackageVersion.create!(work_package: work_package_with_version, version:, kind: "target")
    end

    it "does not create a duplicate" do
      expect { migrate }
        .not_to change { WorkPackageVersion.where(work_package: work_package_with_version, kind: "target").count }
    end

    it "keeps the existing record untouched" do
      migrate

      expect(WorkPackageVersion.where(work_package: work_package_with_version, kind: "target").pluck(:id))
        .to contain_exactly(existing.id)
    end
  end

  context "when an observed_in work_package_version exists for the same version" do
    let!(:observed) do
      WorkPackageVersion.create!(work_package: work_package_with_version, version:, kind: "observed_in")
    end

    it "still backfills the target entry alongside it" do
      migrate

      expect(WorkPackageVersion.where(work_package: work_package_with_version).pluck(:version_id, :kind))
        .to contain_exactly([version.id, "target"], [version.id, "observed_in"])
    end
  end

  it "is idempotent when run twice" do
    migrate

    expect { ActiveRecord::Migration.suppress_messages { described_class.new.up } }
      .not_to change(WorkPackageVersion, :count)
  end
end
