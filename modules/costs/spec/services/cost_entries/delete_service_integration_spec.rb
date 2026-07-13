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

RSpec.describe CostEntries::DeleteService, "integration", type: :model do
  let(:project) { create(:project_with_types) }
  let(:work_package) { create(:work_package, project:, type: project.types.first) }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:owner) { user }
  let(:cost_entry) do
    create(:cost_entry, project:, entity: work_package, user: owner, units: 1)
  end

  subject(:service_call) { described_class.new(user:, model: cost_entry).call }

  context "when deleting own entry with edit_own_cost_entries" do
    let(:permissions) { %i[view_work_packages view_cost_entries edit_own_cost_entries] }

    it "deletes the entry" do
      cost_entry
      expect { service_call }.to change(CostEntry, :count).by(-1)
      expect(service_call).to be_success
    end
  end

  context "when deleting a foreign entry with only edit_own_cost_entries" do
    let(:permissions) { %i[view_work_packages view_cost_entries edit_own_cost_entries] }
    let(:owner) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "is unauthorized and keeps the entry" do
      cost_entry
      expect { service_call }.not_to change(CostEntry, :count)
      expect(service_call).not_to be_success
      expect(service_call.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end
end
