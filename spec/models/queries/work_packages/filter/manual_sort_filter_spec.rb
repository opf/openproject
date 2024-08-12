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

RSpec.describe Queries::WorkPackages::Filter::ManualSortFilter do
  let!(:in_order) { create(:work_package) }
  let!(:in_order2) { create(:work_package) }
  let!(:out_order) { create(:work_package) }

  let(:ar_double) { double(ActiveRecord::Relation, pluck: [in_order2.id, in_order.id]) }
  let(:query_double) { double(Query, ordered_work_packages: ar_double) }

  let(:instance) do
    described_class.create!(name: :manual_sort, context: query_double, operator: "ow", values: [])
  end

  describe "#where" do
    it "filters based on the manual sort order" do
      expect(WorkPackage.where(instance.where))
        .to contain_exactly(in_order2, in_order)
    end
  end
end
