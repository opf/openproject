require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery::Validation do
  class SomeBase
    include CostQuery::Validation
  end

  it "should be valid with no validations whatsoever" do
    obj = SomeBase.new
    obj.validate("foo").should be_true
    obj.validations.size.should == 0
  end

  it "should allow for multiple validations" do
    obj = SomeBase.new
    obj.register_validations([:integers, :dates])
    obj.validations.size.should == 2
  end

  it "should have errors set when we try to validate something invalid" do
    obj = SomeBase.new
    obj.register_validation(:integers)
    obj.validate("this ain't a number, right?").should be_false
    obj.errors[:int].size.should == 1
  end

  it "should have no errors set when we try to validate something valid" do
    obj = SomeBase.new
    obj.register_validation(:integers)
    obj.validate(1,2,3,4).should be_true
    obj.errors[:int].size.should == 0
  end

  it "should validate integers correctly" do
    obj = SomeBase.new
    obj.register_validation(:integers)
    obj.validate(1,2,3,4).should be_true
    obj.errors[:int].size.should == 0
    obj.validate("I ain't gonna work on Maggies Farm no more").should be_false
    obj.errors[:int].size.should == 1
    obj.validate("You've got the touch!", "You've got the power!").should be_false
    obj.errors[:int].size.should == 2
    obj.validate(1, "This is a good burger").should be_false
    obj.errors[:int].size.should == 1
  end

  it "should validate dates correctly" do
    obj = SomeBase.new
    obj.register_validation(:dates)
    obj.validate("2010-04-15").should be_true
    obj.errors[:date].size.should == 0
    obj.validate("2010-15-15").should be_false
    obj.errors[:date].size.should == 1
    obj.validate("2010-04-31").should be_false
    obj.errors[:date].size.should == 1
  end

end