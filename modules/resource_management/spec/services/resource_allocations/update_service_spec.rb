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
