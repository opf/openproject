#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "CostQuery::Validation", type: :model do
  class CostQuery::SomeBase
    include CostQuery::Validation
  end

  it "should be valid with no validations whatsoever" do
    obj = CostQuery::SomeBase.new
    expect(obj.validate("foo")).to be_truthy
    expect(obj.validations.size).to eq(0)
  end

  it "should allow for multiple validations" do
    obj = CostQuery::SomeBase.new
    obj.register_validations([:integers, :dates])
    expect(obj.validations.size).to eq(2)
  end

  it "should have errors set when we try to validate something invalid" do
    obj = CostQuery::SomeBase.new
    obj.register_validation(:integers)
    expect(obj.validate("this ain't a number, right?")).to be_falsey
    expect(obj.errors[:int].size).to eq(1)
  end

  it "should have no errors set when we try to validate something valid" do
    obj = CostQuery::SomeBase.new
    obj.register_validation(:integers)
    expect(obj.validate(1,2,3,4)).to be_truthy
    expect(obj.errors[:int].size).to eq(0)
  end

  it "should validate integers correctly" do
    obj = CostQuery::SomeBase.new
    obj.register_validation(:integers)
    expect(obj.validate(1,2,3,4)).to be_truthy
    expect(obj.errors[:int].size).to eq(0)
    expect(obj.validate("I ain't gonna work on Maggies Farm no more")).to be_falsey
    expect(obj.errors[:int].size).to eq(1)
    expect(obj.validate("You've got the touch!", "You've got the power!")).to be_falsey
    expect(obj.errors[:int].size).to eq(2)
    expect(obj.validate(1, "This is a good burger")).to be_falsey
    expect(obj.errors[:int].size).to eq(1)
  end

  it "should validate dates correctly" do
    obj = CostQuery::SomeBase.new
    obj.register_validation(:dates)
    expect(obj.validate("2010-04-15")).to be_truthy
    expect(obj.errors[:date].size).to eq(0)
    expect(obj.validate("2010-15-15")).to be_falsey
    expect(obj.errors[:date].size).to eq(1)
    expect(obj.validate("2010-04-31")).to be_falsey
    expect(obj.errors[:date].size).to eq(1)
  end

end
