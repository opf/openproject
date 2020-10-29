# -*- encoding:  utf-8 -*-
require 'helper'
require 'duration/mongoid'
require 'mongoid'

describe "mongoid support" do
  before do
    class MyModel
      include Mongoid::Document
      field :duration, :type => Duration
    end
    @model = MyModel.new
  end

  describe "assigning an integer value" do
    it "should return the duration given the total in seconds" do
      @model.duration = 90
      assert_equal @model.duration, Duration.new(90)
    end

    it "assigning a nil value" do
      @model.duration = nil
      assert_nil @model.duration
    end
  end

  describe "assigning an array" do
    it "should return nil" do
      @model.duration = [1,2,3]
      assert_nil @model.duration
    end
  end

  describe "assigning a valid hash" do
    it "should return total seconds given a duration in hash" do
      @model.duration = { :minutes => 1, :seconds => 30 }
      assert_equal Duration.new({ :minutes => 1, :seconds => 30 }), @model.duration
    end
  end

  describe "assigning invalid hashes" do
    it "should return nil" do
      [{}, {:seconds => "", :hours => ""}, {:x => 100, :seconds => ""}].each do |value|
        @model.duration = value
        assert_nil @model.duration
      end
    end
  end

  describe "assigning a Duration object" do
    it "should return the duration value" do
      duration = Duration.new(:minutes => 1, :seconds => 30)
      @model.duration = duration
      assert_equal duration, @model.duration
    end
  end

  describe "assigning a string" do
    it "should return total seconds given a duration in string" do
      @model.duration = "10"
      assert_equal Duration.new(10), @model.duration

      @model.duration = "10string"
      assert_equal Duration.new(10), @model.duration

      @model.duration = "string"
      assert_equal Duration.new(0), @model.duration
    end
  end
end
