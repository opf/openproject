require File.dirname(__FILE__) + '/../spec_helper'

describe Rate do

  fixtures :cost_types
  fixtures :rates

  describe "changing valid_from" do

    it "should update all cost_entries correctly when rates change without changing order" do
      pending
    end

    it "should update all cost_entries correctly when rates change order" do
      pending
    end

    it "should update all cost_entries correctly when a rate is added before all other rates" do
      pending
    end

    it "should update all cost_entries correctly when a rate is added after all other rates" do
      pending
    end

    it "should update all cost_entries correctly when a rate is added between two other rates" do
      pending
    end

    it "should update all cost_entries correctly when a rate is removed" do
      pending
    end

  end

end