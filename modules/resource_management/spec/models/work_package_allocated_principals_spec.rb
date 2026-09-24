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

RSpec.describe WorkPackage, "allocated principals" do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:member) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:outsider) { create(:user, member_with_permissions: { other_project => %i[view_work_packages] }) }
  shared_let(:work_package) { create(:work_package, project:) }

  before { login_as(viewer) }

  describe "#allocated_principals" do
    it "lists every allocated user once" do
      create(:resource_allocation, entity: work_package, principal: member)
      create(:resource_allocation, entity: work_package, principal: member)

      expect(work_package.allocated_principals).to contain_exactly(member)
    end

    it "ignores allocations that are not confirmed" do
      create(:resource_allocation, :requested, entity: work_package, principal: member)

      expect(work_package.allocated_principals).to be_empty
    end

    it "shows the placeholder a generic allocation was requested for, even once staffed" do
      allocation = create(:resource_allocation, :with_user_filter, entity: work_package)
      allocation.update!(principal: member)

      expect(work_package.allocated_principals).to contain_exactly(allocation.placeholder_user)
    end

    it "omits users the viewer may not see" do
      create(:resource_allocation, entity: work_package, principal: outsider)

      expect(work_package.allocated_principals).to be_empty
    end

    it "always lists placeholders" do
      allocation = create(:resource_allocation, :with_user_filter, entity: work_package)

      expect(work_package.allocated_principals).to contain_exactly(allocation.placeholder_user)
    end
  end

  describe "collection eager loading" do
    shared_let(:other_work_package) { create(:work_package, project:) }

    it "preloads the allocated principals in the wrapped collection query" do
      create(:resource_allocation, entity: work_package, principal: member)
      placeholder_allocation = create(:resource_allocation, :with_user_filter, entity: other_work_package)

      wrapped = API::V3::WorkPackages::WorkPackageEagerLoadingWrapper
                  .wrap([work_package.id, other_work_package.id], viewer)

      expect { wrapped.map(&:allocated_principals) }.to have_a_query_limit(0)
      expect(wrapped.map(&:allocated_principals)).to eq([[member], [placeholder_allocation.placeholder_user]])
    end
  end
end
