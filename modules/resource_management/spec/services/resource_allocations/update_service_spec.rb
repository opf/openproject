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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe ResourceAllocations::UpdateService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:owner) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners allocate_user_resources] })
  end
  shared_let(:work_package) { create(:work_package, project:) }

  let!(:resource_allocation) do
    create(:resource_allocation, entity: work_package, principal: owner, state: "requested", allocated_time: 8)
  end

  subject(:service_call) do
    described_class.new(user: owner, model: resource_allocation).call(state: "allocated", allocated_time: 16)
  end

  it "updates the resource allocation" do
    expect(service_call).to be_success
    expect(resource_allocation.reload.state).to eq("allocated")
    expect(resource_allocation.allocated_time).to eq(16)
  end

  context "for the user who assigned the principal" do
    shared_let(:previous_assigner) { create(:user) }
    shared_let(:other_member) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    before { resource_allocation.update_column(:principal_assigned_by_id, previous_assigner.id) }

    it "records the acting user when the principal changes" do
      result = described_class.new(user: owner, model: resource_allocation).call(principal: other_member)

      expect(result).to be_success
      expect(resource_allocation.reload.principal_assigned_by).to eq(owner)
    end

    it "keeps the previous assigner when the principal stays the same" do
      result = described_class.new(user: owner, model: resource_allocation).call(allocated_time: 16)

      expect(result).to be_success
      expect(resource_allocation.reload.principal_assigned_by).to eq(previous_assigner)
    end
  end

  context "when re-staffing a staffed allocation" do
    shared_let(:placeholder) { create(:placeholder_user) }
    shared_let(:other_member) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    before { resource_allocation.update_column(:placeholder_user_id, placeholder.id) }

    it "assigns the picked user and keeps the placeholder" do
      result = described_class.new(user: owner, model: resource_allocation).call(placeholder_or_user: other_member)

      expect(result).to be_success
      resource_allocation.reload
      expect(resource_allocation.principal).to eq(other_member)
      expect(resource_allocation.placeholder_user).to eq(placeholder)
      expect(resource_allocation.principal_assigned_by).to eq(owner)
    end
  end

  context "when the assignee has been deleted" do
    shared_let(:deleted_user) { create(:deleted_user) }

    before { resource_allocation.update_column(:principal_id, deleted_user.id) }

    it "updates the allocation and keeps the deleted user" do
      expect(service_call).to be_success
      expect(resource_allocation.reload.allocated_time).to eq(16)
      expect(resource_allocation.principal).to eq(deleted_user)
    end
  end

  context "when attempting to change the entity" do
    let(:other_work_package) { create(:work_package, project:) }

    it "fails because entity is not writable" do
      result = described_class.new(user: owner, model: resource_allocation).call(entity: other_work_package)
      expect(result).not_to be_success
      expect(result.errors.symbols_for(:entity_id)).to include(:error_readonly)
      expect(resource_allocation.reload.entity).to eq(work_package)
    end
  end

  context "when user lacks allocate_user_resources" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

    it "fails with an authorization error" do
      result = described_class.new(user:, model: resource_allocation).call(state: "allocated")
      expect(result).not_to be_success
      expect(result.errors[:base]).to include(I18n.t("activerecord.errors.messages.error_unauthorized"))
    end
  end
end
