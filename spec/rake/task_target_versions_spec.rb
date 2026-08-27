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

RSpec.describe Rake::Task do
  shared_let(:project) { create(:project) }

  # Reinstates a stale target version the same way the deleted repair job did:
  # a direct target row insert followed by a system journal carrying its cause.
  def build_stale_target_version
    version_a = create(:version, project:, name: "A")
    version_b = create(:version, project:, name: "B")

    work_package = create(:work_package, project:)
    travel(6.minutes)

    work_package.add_journal(user: create(:user))
    work_package.target_version_ids_replacements = [version_a.id]
    work_package.save!
    travel(6.minutes)

    work_package.add_journal(user: create(:user))
    work_package.target_version_ids_replacements = [version_b.id]
    work_package.save!

    work_package.update_column(:version_id, version_a.id)
    travel(6.minutes)

    WorkPackageVersion.create!(work_package:, version: version_a, kind: "target")
    Journal::NotificationConfiguration.with(false) do
      Journals::CreateService.new(work_package, User.system).call(
        cause: Journal::CausedBySystemUpdate.new(feature: "target_versions_repaired")
      )
    end

    [work_package, version_a, version_b]
  end

  describe "target_versions:stale:report" do
    include_context "rake" do
      let(:task_name) { "target_versions:stale:report" }
    end

    it "prints the finding without removing the stale target version" do
      work_package, version_a, version_b = build_stale_target_version

      expect { subject.invoke }.to output(/##{work_package.id}/).to_stdout
      expect(WorkPackageVersion.where(work_package_id: work_package.id, kind: "target").pluck(:version_id))
        .to contain_exactly(version_a.id, version_b.id)
    end
  end

  describe "target_versions:stale:fix" do
    include_context "rake" do
      let(:task_name) { "target_versions:stale:fix" }
    end

    it "removes the stale target version" do
      work_package, _version_a, version_b = build_stale_target_version

      subject.invoke

      expect(WorkPackageVersion.where(work_package_id: work_package.id, kind: "target").pluck(:version_id))
        .to contain_exactly(version_b.id)
    end
  end
end
