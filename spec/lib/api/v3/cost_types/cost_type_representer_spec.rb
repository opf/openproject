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
  let(:project) { FactoryGirl.build(:project, id: 999) }
  let(:user) { FactoryGirl.build(:user,
                                 member_in_project: project,
                                 created_on: 1.day.ago,
                                 updated_on: Date.today) }
  let(:work_package) { FactoryGirl.build(:work_package,
                                         project: project) }
  let(:cost_type) { FactoryGirl.build(:cost_type) }
  let!(:cost_entry) { FactoryGirl.build(:cost_entry,
                                        work_package: nil,
                                        project: project,
                                        units: 3,
                                        spent_on: Date.today,
                                        user: user,
                                        comments: "Entry 1") }

  let(:representer)  { described_class.new(cost_type, work_package: work_package) }

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
  end
end
