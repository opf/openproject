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

RSpec.describe CostEntries::CreateService, "integration", type: :model do
  let(:project) { create(:project_with_types) }
  let(:work_package) { create(:work_package, project:, type: project.types.first) }
  let(:cost_type) { create(:cost_type) }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:permissions) { %i[view_work_packages log_costs] }

  let(:params) do
    {
      entity_type: "WorkPackage",
      entity_id: work_package.id,
      user_id: user.id,
      cost_type_id: cost_type.id,
      units: "5",
      overridden_costs: "500",
      comments: ""
    }
  end

  subject(:service_call) { described_class.new(user:).call(params) }

  it "creates the cost entry, derives the project and records the logging user" do
    expect(service_call).to be_success

    cost_entry = service_call.result
    expect(cost_entry).to be_persisted
    expect(cost_entry.project).to eq(project)
    expect(cost_entry.entity).to eq(work_package)
    expect(cost_entry.user).to eq(user)
    expect(cost_entry.logged_by).to eq(user)
    expect(cost_entry.units).to eq(5)
    expect(cost_entry.overridden_costs).to eq(500)
  end

  context "when no date is given" do
    before { params.delete(:spent_on) }

    it "defaults spent_on to today" do
      expect(service_call).to be_success
      expect(service_call.result.spent_on).to eq(Time.zone.today)
    end
  end

  context "when the cost type does not exist" do
    before { params[:cost_type_id] = 0 }

    it "fails validation" do
      expect(service_call).not_to be_success
      expect(service_call.result.cost_type).to be_nil
      expect(service_call.errors.symbols_for(:cost_type_id)).to include(:invalid)
    end
  end

  context "when the work package is not visible to the user" do
    let(:other_work_package) { create(:work_package) }

    before { params[:entity_id] = other_work_package.id }

    it "assigns the entity but fails the visibility validation in the contract" do
      expect(service_call).not_to be_success
      expect(service_call.result.entity).to eq(other_work_package)
      expect(service_call.errors.symbols_for(:entity)).to include(:invalid)
    end
  end

  context "when the user may only log own costs and logs for somebody else" do
    let(:permissions) { %i[view_work_packages log_own_costs] }
    let(:other_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    before { params[:user_id] = other_user.id }

    it "is unauthorized" do
      expect(service_call).not_to be_success
      expect(service_call.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end

  context "when the user may only log own costs and logs for themselves" do
    let(:permissions) { %i[view_work_packages log_own_costs] }

    it "succeeds" do
      expect(service_call).to be_success
    end
  end
end
