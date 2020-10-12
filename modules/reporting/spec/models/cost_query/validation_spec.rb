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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "CostQuery::Validation", type: :model do
  class CostQuery::SomeBase
    include CostQuery::Validation

    def engine
      CostQuery
    end
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
