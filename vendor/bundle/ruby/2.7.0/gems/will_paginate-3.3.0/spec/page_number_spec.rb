require 'spec_helper'
require 'will_paginate/page_number'
require 'json'

describe WillPaginate::PageNumber do
  describe "valid" do
    def num
      WillPaginate::PageNumber.new('12', 'page')
    end

    it "== 12" do
      num.should eq(12)
    end

    it "inspects to 'page 12'" do
      num.inspect.should eq('page 12')
    end

    it "is a PageNumber" do
      (num.instance_of? WillPaginate::PageNumber).should be
    end

    it "is a kind of Numeric" do
      (num.is_a? Numeric).should be
    end

    it "is a kind of Integer" do
      (num.is_a? Integer).should be
    end

    it "isn't directly a Integer" do
      (num.instance_of? Integer).should_not be
    end

    it "passes the PageNumber=== type check" do |variable|
      (WillPaginate::PageNumber === num).should be
    end

    it "passes the Numeric=== type check" do |variable|
      (Numeric === num).should be
    end

    it "fails the Numeric=== type check" do |variable|
      (Integer === num).should_not be
    end

    it "serializes as JSON number" do
      JSON.dump(page: num).should eq('{"page":12}')
    end
  end

  describe "invalid" do
    def create(value, name = 'page')
      described_class.new(value, name)
    end

    it "errors out on non-int values" do
      lambda { create(nil) }.should raise_error(WillPaginate::InvalidPage)
      lambda { create('') }.should raise_error(WillPaginate::InvalidPage)
      lambda { create('Schnitzel') }.should raise_error(WillPaginate::InvalidPage)
    end

    it "errors out on zero or less" do
      lambda { create(0) }.should raise_error(WillPaginate::InvalidPage)
      lambda { create(-1) }.should raise_error(WillPaginate::InvalidPage)
    end

    it "doesn't error out on zero for 'offset'" do
      lambda { create(0, 'offset') }.should_not raise_error
      lambda { create(-1, 'offset') }.should raise_error(WillPaginate::InvalidPage)
    end
  end

  describe "coercion method" do
    it "defaults to 'page' name" do
      num = WillPaginate::PageNumber(12)
      num.inspect.should eq('page 12')
    end

    it "accepts a custom name" do
      num = WillPaginate::PageNumber(12, 'monkeys')
      num.inspect.should eq('monkeys 12')
    end

    it "doesn't affect PageNumber instances" do
      num = WillPaginate::PageNumber(12)
      num2 = WillPaginate::PageNumber(num)
      num2.object_id.should eq(num.object_id)
    end
  end
end
