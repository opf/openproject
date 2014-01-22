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

describe VariableCostObject do
  let(:cost_object) { FactoryGirl.build(:variable_cost_object) }
  let(:type) { FactoryGirl.create(:type_feature) }
  let(:project) { FactoryGirl.create(:project_with_types) }
  let(:user) { FactoryGirl.create(:user) }

  describe 'recreate initial journal' do
    before do
      User.stub!(:current).and_return(user)

      @variable_cost_object = FactoryGirl.create(:variable_cost_object , :project => project,
                                                                     :author => user)

      @initial_journal = @variable_cost_object.journals.first
      @recreated_journal = @variable_cost_object.recreate_initial_journal!
    end

    it { @initial_journal.should be_identical(@recreated_journal) }
  end

  describe "initialization" do
    let(:cost_object) { VariableCostObject.new }

    before do
      User.stub!(:current).and_return(user)
    end

    it { cost_object.author.should == user }
  end

  describe "destroy" do
    let(:work_package) { FactoryGirl.create(:work_package) }

    before do
      cost_object.author = user
      cost_object.work_packages = [work_package]
      cost_object.save!

      cost_object.destroy
    end

    it { VariableCostObject.find_by_id(cost_object.id).should be_nil }
    it { WorkPackage.find_by_id(work_package.id).should == work_package }
    it { work_package.reload.cost_object.should be_nil }
  end
end
