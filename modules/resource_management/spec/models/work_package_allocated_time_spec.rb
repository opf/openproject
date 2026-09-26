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

RSpec.describe WorkPackage, "allocated time" do
  shared_let(:work_package1) { create(:work_package) }
  shared_let(:work_package2) { create(:work_package) }
  shared_let(:unallocated_work_package) { create(:work_package) }

  before do
    create(:resource_allocation, entity: work_package1, allocated_time: 120)
    create(:resource_allocation, entity: work_package1, allocated_time: 30)
    create(:resource_allocation, :requested, entity: work_package1, allocated_time: 600)
    create(:resource_allocation, entity: work_package2, allocated_time: 480)
  end

  describe ".include_allocated_time" do
    let(:work_package_scope) { described_class.where(id: [work_package1.id, unallocated_work_package.id]) }

    it "selects the confirmed allocated minutes along with the work packages" do
      work_packages = work_package_scope.select("work_packages.*").include_allocated_time(work_package_scope).to_a

      expect { work_packages.map(&:allocated_minutes) }.to have_a_query_limit(0)
      expect(work_packages.to_h { [it.id, it.allocated_minutes] })
        .to eq(work_package1.id => 150, unallocated_work_package.id => 0)
    end
  end

  describe "#allocated_minutes" do
    it "sums the confirmed allocations when not preloaded" do
      expect(work_package1.allocated_minutes).to eq(150)
    end
  end

  describe "collection eager loading" do
    it "preloads the allocated minutes in the wrapped collection query" do
      wrapped = API::V3::WorkPackages::WorkPackageEagerLoadingWrapper
                  .wrap([work_package1.id, work_package2.id, unallocated_work_package.id], create(:admin))

      expect { wrapped.map(&:allocated_minutes) }.to have_a_query_limit(0)
      expect(wrapped.map(&:allocated_minutes)).to eq([150, 480, 0])
    end
  end
end
