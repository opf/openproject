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

RSpec.describe WorkPackage, "asking before destroying resource allocations" do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking resource_management]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[work_package_tracking resource_management]) }
  shared_let(:third_project) { create(:project, enabled_module_names: %i[work_package_tracking resource_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages view_resource_planners allocate_user_resources],
             other_project => %i[view_work_packages],
             third_project => %i[view_work_packages view_resource_planners allocate_user_resources]
           })
  end

  let(:work_package) { create(:work_package, project:) }
  let(:target) { create(:work_package, project:) }
  let(:allocated_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  let(:allocation) { create(:resource_allocation, entity: work_package, principal: allocated_user) }

  def cleanup(to_do)
    described_class.cleanup_associated_before_destructing_if_required(work_package, user, to_do)
  end

  describe ".associated_classes_to_address_before_destruction_of" do
    it "includes resource allocations when the work package has some" do
      allocation

      expect(described_class.associated_classes_to_address_before_destruction_of(work_package)).to include(ResourceAllocation)
    end

    it "leaves them out when it has none" do
      expect(described_class.associated_classes_to_address_before_destruction_of(work_package)).not_to include(ResourceAllocation)
    end
  end

  describe ".cleanup_associated_before_destructing_if_required" do
    before { allocation }

    it "lets the allocations go with the work package when asked to destroy them" do
      expect(cleanup(action: "destroy")).to be(true)
      expect(allocation.reload.entity).to eq(work_package)
    end

    it "refuses to keep them without a work package" do
      expect(cleanup(action: "nullify")).to be(false)
      expect(work_package.errors[:base]).to include("Resource allocations can not be assigned to a project.")
      expect(allocation.reload.entity).to eq(work_package)
    end

    it "moves them to another work package" do
      expect(cleanup(action: "reassign", reassign_to_id: target.id)).to be(true)
      expect(allocation.reload.entity).to eq(target)
    end

    it "journals the move" do
      expect { cleanup(action: "reassign", reassign_to_id: target.id) }
        .to change { allocation.journals.count }.by(1)
      expect(allocation.last_journal.data.entity_id).to eq(target.id)
    end

    context "when the allocated user is not a member of the target's project" do
      let(:target) { create(:work_package, project: third_project) }

      it "refuses to move them there" do
        expect(cleanup(action: "reassign", reassign_to_id: target.id)).to be(false)
        expect(work_package.errors.full_messages).to include(a_string_matching(/not a member/))
        expect(allocation.reload.entity).to eq(work_package)
      end
    end

    context "when the user may not allocate in the target's project" do
      let(:target) { create(:work_package, project: other_project) }

      it "refuses to move them there" do
        expect(cleanup(action: "reassign", reassign_to_id: target.id)).to be(false)
        expect(work_package.errors[:base])
          .to include("Work package ##{target.id} is not a valid target for reassigning the resource allocations.")
        expect(allocation.reload.entity).to eq(work_package)
      end
    end
  end
end
