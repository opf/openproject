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

RSpec.describe Query, "manual sorting " do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:query) { create(:query, user:, project:) }
  shared_let(:wp_1) do
    User.execute_as user do
      create(:work_package, project:)
    end
  end
  shared_let(:wp_2) do
    User.execute_as user do
      create(:work_package, project:)
    end
  end

  before do
    login_as user
  end

  describe "#ordered_work_packages" do
    it "keeps the current set of ordered work packages" do
      expect(query.ordered_work_packages).to eq []

      expect(OrderedWorkPackage.where(query_id: query.id).count).to eq 0

      query.ordered_work_packages.build(work_package_id: wp_1.id, position: 0)
      query.ordered_work_packages.build(work_package_id: wp_2.id, position: 1)

      expect(OrderedWorkPackage.where(query_id: query.id).count).to eq 0
      expect(query.save).to be true
      expect(OrderedWorkPackage.where(query_id: query.id).count).to eq 2

      query.reload
      expect(query.ordered_work_packages.pluck(:work_package_id)).to eq [wp_1.id, wp_2.id]
    end
  end

  describe "with a second query on the same work package" do
    let(:query2) { create(:query, user:, project:) }

    before do
      OrderedWorkPackage.create(query:, work_package: wp_1, position: 0)
      OrderedWorkPackage.create(query:, work_package: wp_2, position: 1)

      OrderedWorkPackage.create(query: query2, work_package: wp_1, position: 4)
      OrderedWorkPackage.create(query: query2, work_package: wp_2, position: 3)
    end

    it "returns the correct number of work packages" do
      query.add_filter("manual_sort", "ow", [])
      query2.add_filter("manual_sort", "ow", [])

      query.sort_criteria = [[:manual_sorting, "asc"]]
      query2.sort_criteria = [[:manual_sorting, "asc"]]

      expect(query.results.work_packages.pluck(:id)).to eq [wp_1.id, wp_2.id]
      expect(query2.results.work_packages.pluck(:id)).to eq [wp_2.id, wp_1.id]
    end
  end
end
