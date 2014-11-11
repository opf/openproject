#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'spec_helper'

describe ::API::V3::CostTypes::CostTypeRepresenter do
  let(:project1) { FactoryGirl.create(:project) }
  let(:project2) { FactoryGirl.create(:project) }
  let(:role) {
    FactoryGirl.create(:role, permissions: [:view_work_package, :view_own_cost_entries])
  }
  let(:user1) {
    FactoryGirl.create(:user,
                       member_in_projects: [project1, project2],
                       member_through_role: role,
                       created_on: 1.day.ago,
                       updated_on: Date.today)
  }
  let(:user2) {
    FactoryGirl.create(:user,
                       member_in_projects: [project1, project2],
                       member_through_role: role,
                       created_on: 1.day.ago,
                       updated_on: Date.today)
  }
  let(:work_package1) { FactoryGirl.create(:work_package, project: project1) }
  let(:work_package2) { FactoryGirl.create(:work_package, project: project2) }
  let(:cost_type1) { FactoryGirl.create(:cost_type) }
  let(:cost_type2) { FactoryGirl.create(:cost_type) }
  let!(:cost_entry11) {
    FactoryGirl.create(:cost_entry,
                       cost_type: cost_type1,
                       work_package: work_package1,
                       project: project1,
                       units: 3,
                       spent_on: Date.today,
                       user_id: user1.id,
                       comments: 'Entry 1')
  }
  let!(:cost_entry12) {
    FactoryGirl.create(:cost_entry,
                       cost_type: cost_type2,
                       work_package: work_package1,
                       project: project1,
                       units: 3,
                       spent_on: Date.today,
                       user_id: user1.id,
                       comments: 'Entry 2')
  }
  let!(:cost_entry13) {
    FactoryGirl.create(:cost_entry,
                       cost_type: cost_type1,
                       work_package: work_package1,
                       project: project1,
                       units: 3,
                       spent_on: Date.today,
                       user_id: user2.id,
                       comments: 'Entry 3')
  }
  let!(:cost_entry21) {
    FactoryGirl.create(:cost_entry,
                       cost_type: cost_type1,
                       work_package: work_package2,
                       project: project2,
                       units: 3,
                       spent_on: Date.today,
                       user: user1,
                       comments: 'Entry 1')
  }
  let!(:cost_entry22) {
    FactoryGirl.create(:cost_entry,
                       cost_type: cost_type2,
                       work_package: work_package2,
                       project: project2,
                       units: 3,
                       spent_on: Date.today,
                       user: user1,
                       comments: 'Entry 2')
  }

  let(:representer) do
    described_class.new(cost_type1,
                        { unit: 'tonne', unit_plural: 'tonnes' },
                        work_package: work_package1,
                        current_user: user1)
  end

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { should include_json('CostType'.to_json).at_path('_type') }

    describe 'cost_type' do
      it { should have_json_path('id') }

      it { should have_json_path('name') }

      it { should have_json_path('units') }
      it { should have_json_path('unit') }
      it { should have_json_path('unitPlural') }
    end

    describe 'units' do
      it 'shows only cost entries of type cost_type1 for user1 in project project1' do
        should be_json_eql(cost_entry11.units.to_json).at_path('units')
      end
    end
  end
end
