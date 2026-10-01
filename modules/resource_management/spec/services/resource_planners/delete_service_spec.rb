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

RSpec.describe ResourcePlanners::DeleteService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:owner) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end

  let(:public_planner) { false }
  let!(:resource_planner) { create(:resource_planner, project:, principal: owner, public: public_planner) }

  subject(:service_call) do
    described_class.new(user:, model: resource_planner).call
  end

  context "when the owner deletes their planner" do
    let(:user) { owner }

    it "destroys the planner" do
      expect { service_call }.to change(ResourcePlanner, :count).by(-1)
      expect(service_call).to be_success
    end
  end

  context "when a manage_public user deletes another user's public planner" do
    let(:public_planner) { true }
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
    end

    it "destroys the planner" do
      expect { service_call }.to change(ResourcePlanner, :count).by(-1)
    end
  end

  context "when a manage_public user attempts to delete another user's private planner" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
    end

    it "fails without destroying" do
      expect { service_call }.not_to change(ResourcePlanner, :count)
      expect(service_call).not_to be_success
    end
  end

  context "when an unauthorized user attempts to delete" do
    let(:user) { create(:user) }

    it "fails without destroying" do
      expect { service_call }.not_to change(ResourcePlanner, :count)
      expect(service_call).not_to be_success
    end
  end
end
