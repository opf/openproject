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

RSpec.describe CostEntries::UpdateService, "integration", type: :model do
  let(:project) { create(:project_with_types) }
  let(:work_package) { create(:work_package, project:, type: project.types.first) }
  let(:cost_type) { create(:cost_type) }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:permissions) { %i[view_work_packages view_cost_entries edit_own_cost_entries] }
  let(:owner) { user }
  let(:cost_entry) do
    create(:cost_entry, project:, entity: work_package, cost_type:, user: owner, units: 1)
  end

  subject(:service_call) { described_class.new(user:, model: cost_entry).call(params) }

  context "when updating own entry's units" do
    let(:params) { { units: "9" } }

    it "succeeds" do
      expect(service_call).to be_success
      expect(cost_entry.reload.units).to eq(9)
    end
  end

  context "when reassigning own entry to another user with only edit_own permission" do
    let(:other_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
    let(:params) { { user_id: other_user.id } }

    it "is unauthorized" do
      expect(service_call).not_to be_success
      expect(service_call.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end

  context "when editing a foreign entry with only edit_own permission" do
    let(:owner) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
    let(:params) { { units: "9" } }

    it "is unauthorized" do
      expect(service_call).not_to be_success
      expect(service_call.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end

  context "when moving the entry to a work package in another project" do
    let(:permissions) { %i[view_work_packages view_cost_entries edit_cost_entries] }
    let(:target_project) { create(:project_with_types) }
    let(:target_work_package) { create(:work_package, project: target_project, type: target_project.types.first) }
    let(:params) { { entity_type: "WorkPackage", entity_id: target_work_package.id } }

    before do
      # The user can even see work packages in the target project
      create(:member,
             principal: user,
             project: target_project,
             roles: [create(:project_role, permissions: %i[view_work_packages])])
    end

    it "is rejected because the entry keeps its project and the entity no longer matches it" do
      expect(service_call).not_to be_success
      expect(cost_entry.project).to eq(project)
      expect(service_call.errors.symbols_for(:entity)).to include(:invalid)
    end
  end
end
