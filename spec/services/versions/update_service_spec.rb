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

RSpec.describe Versions::UpdateService do
  let(:user) { create(:admin) }
  let(:parent_project) { create(:project) }
  let!(:child_project) { create(:project, parent: parent_project) }
  let(:shared_version) { create(:version, project: parent_project, sharing: "descendants") }
  let!(:work_package) { create(:work_package, project: child_project, version: shared_version) }

  subject(:service_call) { described_class.new(user:, model: shared_version).call(attributes) }

  def target_version_ids(work_package)
    work_package.work_package_versions.where(kind: "target").pluck(:version_id)
  end

  context "when a sharing change makes the version unshared" do
    let(:attributes) { { sharing: "none" } }

    it "prunes only the now-unshared version, keeping the targets that stay shared" do
      own_version = create(:version, project: child_project)
      work_package.work_package_versions.create!(version: own_version, kind: "target")

      expect(service_call).to be_success

      work_package.reload
      expect(target_version_ids(work_package)).to contain_exactly(own_version.id)
    end
  end

  describe "deciding whether to reconcile referencing work packages" do
    before { allow(WorkPackage).to receive(:update_versions_from_sharing_change).and_call_original }

    context "with a narrowing sharing change" do
      let(:attributes) { { sharing: "none" } }

      it "reconciles the work package versions" do
        expect(service_call).to be_success
        expect(WorkPackage).to have_received(:update_versions_from_sharing_change).with(shared_version)
      end
    end

    context "with a broadening sharing change" do
      let(:attributes) { { sharing: "tree" } }

      it "does not reconcile the work package versions" do
        expect(service_call).to be_success
        expect(WorkPackage).not_to have_received(:update_versions_from_sharing_change)
      end
    end

    context "with a change that does not touch sharing" do
      let(:attributes) { { name: "Renamed version" } }

      it "does not reconcile the work package versions" do
        expect(service_call).to be_success
        expect(WorkPackage).not_to have_received(:update_versions_from_sharing_change)
      end
    end
  end
end
