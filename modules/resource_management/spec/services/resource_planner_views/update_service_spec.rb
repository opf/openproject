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

RSpec.describe ResourcePlannerViews::UpdateService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end

  let(:resource_planner) do
    create(:resource_planner, project:, principal: user)
  end
  let(:view) do
    ResourceWorkPackageList.create!(name: "Original", parent: resource_planner, project:, principal: user)
  end

  subject(:service_call) do
    described_class.new(user:, model: view).call(name: "Updated")
  end

  it "updates the view name" do
    expect(service_call).to be_success
    expect(view.reload.name).to eq("Updated")
  end

  it "persists filter changes onto the associated query" do
    described_class
      .new(user:, model: view)
      .call(name: "Updated",
            filter_mode: "automatic",
            filters: [{ assigned_to_id: { operator: "=", values: [user.id.to_s] } }].to_json)

    expect(view.query.reload.filters.map(&:name)).to contain_exactly(:assigned_to_id)
  end

  context "when the user is not allowed to manage the parent planner" do
    let(:other_user) { create(:user) }

    subject(:service_call) do
      described_class.new(user: other_user, model: view).call(name: "Updated")
    end

    it "fails with an authorization error" do
      expect(service_call).not_to be_success
      expect(view.reload.name).to eq("Original")
      expect(service_call.errors[:base]).to include(I18n.t("activerecord.errors.messages.error_unauthorized"))
    end
  end

  it "does not re-parent the view" do
    other_planner = create(:resource_planner, project:, principal: user)
    described_class.new(user:, model: view).call(parent: other_planner)

    expect(view.reload.parent).to eq(resource_planner)
  end
end
