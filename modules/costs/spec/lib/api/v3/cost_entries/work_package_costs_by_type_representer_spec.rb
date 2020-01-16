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

describe ::API::V3::CostEntries::WorkPackageCostsByTypeRepresenter do
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryBot.create(:project) }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:cost_type_A) { FactoryBot.create(:cost_type) }
  let(:cost_type_B) { FactoryBot.create(:cost_type) }
  let(:cost_entries_A) {
    FactoryBot.create_list(:cost_entry,
                            2,
                            units: 1,
                            work_package: work_package,
                            project: project,
                            cost_type: cost_type_A)
  }
  let(:cost_entries_B) {
    FactoryBot.create_list(:cost_entry,
                            3,
                            units: 2,
                            work_package: work_package,
                            project: project,
                            cost_type: cost_type_B)
  }
  let(:current_user) {
    FactoryBot.build(:user, member_in_project: project, member_through_role: role)
  }
  let(:role) { FactoryBot.build(:role, permissions: [:view_cost_entries]) }

  let(:representer) { described_class.new(work_package, current_user: current_user) }

  subject { representer.to_json }

  before do
    # create the lists
    cost_entries_A
    cost_entries_B
  end

  it 'has a type' do
    is_expected.to be_json_eql('Collection'.to_json).at_path('_type')
  end

  it 'has one element per type' do
    is_expected.to have_json_size(2).at_path('_embedded/elements')
  end

  it 'indicates the cost types' do
    elements = JSON.parse(subject)['_embedded']['elements']
    types = elements.map { |entry| entry['_links']['costType']['href'] }
    expect(types).to include(api_v3_paths.cost_type cost_type_A.id)
    expect(types).to include(api_v3_paths.cost_type cost_type_B.id)
  end

  it 'aggregates the units' do
    elements = JSON.parse(subject)['_embedded']['elements']
    units_by_type = elements.inject({}) { |hash, entry|
      hash[entry['_links']['costType']['href']] = entry['spentUnits']
      hash
    }

    expect(units_by_type[api_v3_paths.cost_type cost_type_A.id]).to eql 2.0
    expect(units_by_type[api_v3_paths.cost_type cost_type_B.id]).to eql 6.0
  end
end
