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

RSpec.describe ResourceAllocations::CreateService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:owner) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners allocate_user_resources] })
  end
  shared_let(:work_package) { create(:work_package, project:) }

  let(:assignee) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }
  let(:params) do
    {
      entity: work_package,
      principal: assignee,
      start_date: Date.new(2026, 1, 1),
      end_date: Date.new(2026, 1, 31),
      allocated_time: 8
    }
  end

  subject(:service_call) { described_class.new(user: owner).call(params) }

  it "creates a resource allocation" do
    result = service_call
    expect(result).to be_success, "expected success but got: #{result.errors.full_messages}"
    expect(result.result.entity).to eq(work_package)
    expect(result.result.principal).to eq(assignee)
    expect(result.result.allocated_time).to eq(8)
  end

  it "defaults the state to allocated" do
    expect(service_call.result.state).to eq("allocated")
  end

  it "stamps requested_by and reviewed_by with the calling user" do
    result = service_call
    expect(result.result.requested_by).to eq(owner)
    expect(result.result.reviewed_by).to eq(owner)
  end

  it "ignores requested_by and reviewed_by passed in params" do
    other_user = create(:user)
    result = described_class.new(user: owner).call(
      params.merge(requested_by: other_user, reviewed_by: other_user)
    )
    expect(result).to be_success, "expected success but got: #{result.errors.full_messages}"
    expect(result.result.requested_by).to eq(owner)
    expect(result.result.reviewed_by).to eq(owner)
  end

  it "honors an explicitly-passed state" do
    result = described_class.new(user: owner).call(params.merge(state: "requested"))
    expect(result.result.state).to eq("requested")
  end

  context "when allocated_time is zero" do
    it "fails with a numericality error" do
      result = described_class.new(user: owner).call(params.merge(allocated_time: 0))
      expect(result).not_to be_success
      expect(result.errors.symbols_for(:allocated_time)).to include(:greater_than)
    end
  end

  context "when end_date is before start_date" do
    it "fails the date-range validation" do
      result = described_class.new(user: owner).call(
        params.merge(start_date: Date.new(2026, 2, 1), end_date: Date.new(2026, 1, 1))
      )
      expect(result).not_to be_success
      expect(result.errors.symbols_for(:end_date)).to include(:greater_than_start_date)
    end
  end

  context "when user lacks allocate_user_resources" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

    it "fails with an authorization error" do
      result = described_class.new(user:).call(params)
      expect(result).not_to be_success
      expect(result.errors[:base]).to include(I18n.t("activerecord.errors.messages.error_unauthorized"))
    end
  end
end
