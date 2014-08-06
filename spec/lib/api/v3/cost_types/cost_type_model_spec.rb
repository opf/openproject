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

describe ::API::V3::CostTypes::CostTypeModel do
  include Capybara::RSpecMatchers

  let(:project) { FactoryGirl.build(:project) }
  let(:user) { FactoryGirl.build(:user, member_in_project: project) }
  let(:cost_type) { FactoryGirl.build(:cost_type) }
  let!(:cost_entry) { FactoryGirl.build(:cost_entry,
                                        work_package: nil,
                                        project: project,
                                        units: 3,
                                        spent_on: Date.today,
                                        user: user,
                                        comments: "Entry 1") }

  subject(:model) { ::API::V3::CostTypes::CostTypeModel.new(cost_type) }

  describe 'attributes' do
    it { expect(subject.name).to eq(cost_type.name) }

    it { expect(subject.unit).to eq(cost_type.unit) }

    it { expect(subject.unit_plural).to eq(cost_type.unit_plural) }

    it { expect(subject.units).to eq(cost_type.cost_entries.sum(&:units)) }

    describe 'units' do
      subject(:model) { ::API::V3::CostTypes::CostTypeModel.new(cost_type, units: 42) }

      it { expect(subject.units).to eq(42) }
    end
  end
end
