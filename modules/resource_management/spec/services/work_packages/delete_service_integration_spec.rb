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

RSpec.describe WorkPackages::DeleteService, "ResourceAllocation", type: :model do
  shared_let(:project) { create(:project_with_types) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[delete_work_packages view_work_packages manage_subtasks] })
  end

  let(:work_package) { create(:work_package, project:) }
  let(:other_work_package) { create(:work_package, project:) }

  subject(:delete) { described_class.new(user:, model: work_package).call }

  context "with allocations on the work package" do
    let!(:allocations) do
      ResourceAllocation.states.keys.map { |state| create(:resource_allocation, entity: work_package, state:) }
    end
    let!(:other_allocation) { create(:resource_allocation, entity: other_work_package) }

    it "deletes them, whatever their state" do
      expect(delete).to be_success
      expect(ResourceAllocation.where(id: allocations.map(&:id))).to be_empty
    end

    it "deletes their journals" do
      delete

      expect(Journal.where(journable_type: "ResourceAllocation", journable_id: allocations.map(&:id))).to be_empty
    end

    it "keeps the allocations of other work packages" do
      delete

      expect(other_allocation.reload).to be_present
    end
  end

  context "with an allocation on a descendant of the work package" do
    let(:child) { create(:work_package, project:, parent: work_package) }
    let!(:child_allocation) { create(:resource_allocation, entity: child) }

    it "deletes it along with the descendant" do
      expect(delete).to be_success
      expect(ResourceAllocation.where(id: child_allocation.id)).to be_empty
    end
  end
end
