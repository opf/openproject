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

RSpec.describe Principals::DeleteJob, "ResourceAllocation", type: :model do
  subject(:job) { described_class.perform_now(principal) }

  shared_let(:deleted_user) { create(:deleted_user) }
  let(:principal) { create(:user) }

  context "with a resource allocation assigned to the principal" do
    let!(:allocation) { create(:resource_allocation, principal:) }
    let!(:other_allocation) { create(:resource_allocation, principal: create(:user)) }
    let!(:unassigned_allocation) do
      create(:resource_allocation, principal: nil, principal_explicit: false, filter_name: "Devs")
    end

    it "rewrites the principal to the deleted user placeholder" do
      job

      expect(allocation.reload.principal).to eq deleted_user
    end

    it "does not affect allocations belonging to other users" do
      expect { job }.not_to change { other_allocation.reload.principal }
    end

    it "does not affect unassigned allocations" do
      expect { job }.not_to change { unassigned_allocation.reload.principal_id }
    end
  end

  context "with a resource allocation requested or reviewed by the principal" do
    let!(:requested_allocation) { create(:resource_allocation, requested_by: principal) }
    let!(:reviewed_allocation) { create(:resource_allocation, reviewed_by: principal) }

    it "rewrites requested_by to the deleted user placeholder" do
      job

      expect(requested_allocation.reload.requested_by).to eq deleted_user
    end

    it "rewrites reviewed_by to the deleted user placeholder" do
      job

      expect(reviewed_allocation.reload.reviewed_by).to eq deleted_user
    end
  end
end
