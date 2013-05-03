require File.expand_path('../../spec_helper', __FILE__)

describe PermittedParams do
  let(:user) { FactoryGirl.build(:user) }

  describe :cost_entry do
    it "should return comments" do
      params = ActionController::Parameters.new(:cost_entry => { "comments" => "blubs" } )

      PermittedParams.new(params, user).cost_entry.should == { "comments" => "blubs" }
    end

    it "should return units" do
      params = ActionController::Parameters.new(:cost_entry => { "units" => "5.0" } )

      PermittedParams.new(params, user).cost_entry.should == { "units" => "5.0" }
    end

    it "should return overridden_costs" do
      params = ActionController::Parameters.new(:cost_entry => { "overridden_costs" => "5.0" } )

      PermittedParams.new(params, user).cost_entry.should == { "overridden_costs" => "5.0" }
    end

    it "should return spent_on" do
      params = ActionController::Parameters.new(:cost_entry => { "spent_on" => Date.today.to_s } )

      PermittedParams.new(params, user).cost_entry.should == { "spent_on" => Date.today.to_s }
    end
  end
end
