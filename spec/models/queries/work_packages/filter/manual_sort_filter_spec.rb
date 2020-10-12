#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Queries::WorkPackages::Filter::ManualSortFilter, type: :model do
  let!(:in_order) { FactoryBot.create(:work_package) }
  let!(:in_order2) { FactoryBot.create(:work_package) }
  let!(:out_order) { FactoryBot.create(:work_package) }

  let(:ar_double) { double(ActiveRecord::Relation, pluck: [in_order2.id, in_order.id]) }
  let(:query_double) { double(Query, ordered_work_packages: ar_double) }

  let(:instance) do
    described_class.create!(name: :manual_sort, context: query_double, operator: 'ow', values: [])
  end

  describe '#where' do
    it 'filters based on the manual sort order' do
      expect(WorkPackage.where(instance.where))
        .to match_array [in_order2, in_order]
    end
  end
end
