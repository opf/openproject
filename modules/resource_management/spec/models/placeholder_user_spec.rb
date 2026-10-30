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

RSpec.describe PlaceholderUser do
  describe ".allocatable" do
    shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }

    shared_let(:with_criteria) do
      filters = UserQuery.new.tap { |query| query.where("name", "~", ["dev"]) }.filters
      create(:placeholder_user, name: "Senior Developer", user_filter: filters)
    end

    shared_let(:without_criteria) { create(:placeholder_user, name: "Just a seat") }

    shared_let(:allocator) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners allocate_user_resources] })
    end

    shared_let(:bystander) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

    it "offers placeholders describing who they stand for" do
      expect(described_class.allocatable(allocator)).to contain_exactly(with_criteria)
    end

    it "does not require the permissions that managing placeholders needs" do
      expect(allocator.allowed_globally?(:manage_placeholder_user)).to be(false)
      expect(described_class.visible(allocator)).to be_empty
      expect(described_class.allocatable(allocator)).to include(with_criteria)
    end

    it "is empty for someone who may not allocate" do
      expect(described_class.allocatable(bystander)).to be_empty
    end
  end

  describe "#destroy" do
    let(:placeholder_user) { create(:placeholder_user) }

    it "is prevented while the placeholder user is used in a resource allocation" do
      allocation = create(:resource_allocation, placeholder_user:, principal: nil)

      expect(placeholder_user.destroy).to be(false)
      expect(placeholder_user.errors.details[:base]).to include(error: :"restrict_dependent_destroy.has_many",
                                                                record: anything)
      expect(allocation.reload.placeholder_user).to eq(placeholder_user)
    end

    it "succeeds when the placeholder user is not used in any resource allocation" do
      expect(placeholder_user.destroy).to be_destroyed
    end
  end
end
