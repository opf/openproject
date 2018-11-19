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

require File.dirname(__FILE__) + '/../spec_helper'

describe VariableCostObject, type: :model do
  let(:cost_object) { FactoryBot.build(:variable_cost_object) }
  let(:type) { FactoryBot.create(:type_feature) }
  let(:project) { FactoryBot.create(:project_with_types) }
  let(:user) { FactoryBot.create(:user) }

  describe 'recreate initial journal' do
    before do
      allow(User).to receive(:current).and_return(user)

      @variable_cost_object = FactoryBot.create(:variable_cost_object, project: project,
                                                                        author: user)

      @initial_journal = @variable_cost_object.journals.first
      @recreated_journal = @variable_cost_object.recreate_initial_journal!
    end

    it { expect(@initial_journal).to be_identical(@recreated_journal) }
  end

  describe 'initialization' do
    let(:cost_object) { VariableCostObject.new }

    before do
      allow(User).to receive(:current).and_return(user)
    end

    it { expect(cost_object.author).to eq(user) }
  end

  describe 'destroy' do
    let(:work_package) { FactoryBot.create(:work_package) }

    before do
      cost_object.author = user
      cost_object.work_packages = [work_package]
      cost_object.save!

      cost_object.destroy
    end

    it { expect(VariableCostObject.find_by_id(cost_object.id)).to be_nil }
    it { expect(WorkPackage.find_by_id(work_package.id)).to eq(work_package) }
    it { expect(work_package.reload.cost_object).to be_nil }
  end
end
