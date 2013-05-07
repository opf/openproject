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

    it "should not return project_id" do
      params = ActionController::Parameters.new(:cost_entry => { "project_id" => 42 } )

      PermittedParams.new(params, user).cost_entry.should == { }
    end
  end

  describe :cost_object do
    it "should return comments" do
      params = ActionController::Parameters.new(:cost_object => { "subject" => "subject_test" } )

      PermittedParams.new(params, user).cost_object.should == { "subject" => "subject_test" }
    end

    it "should return description" do
      params = ActionController::Parameters.new(:cost_object => { "description" => "description_test" } )

      PermittedParams.new(params, user).cost_object.should == { "description" => "description_test" }
    end

    it "should return fixed_date" do
      params = ActionController::Parameters.new(:cost_object => { "fixed_date" => "2013-05-06" } )

      PermittedParams.new(params, user).cost_object.should == { "fixed_date" => "2013-05-06" }
    end

    it "should return project_manager_signoff" do
      params = ActionController::Parameters.new(:cost_object => { "project_manager_signoff" => true } )

      PermittedParams.new(params, user).cost_object.should == { "project_manager_signoff" => true }
    end

    it "should return client_signoff" do
      params = ActionController::Parameters.new(:cost_object => { "client_signoff" => true } )

      PermittedParams.new(params, user).cost_object.should == { "client_signoff" => true }
    end

    it "should not return project_id" do
      params = ActionController::Parameters.new(:cost_object => { "project_id" => 42 } )

      PermittedParams.new(params, user).cost_object.should == { }
    end
  end

  describe :cost_type do
    it "should return name" do
      params = ActionController::Parameters.new(:cost_type => { "name" => "name_test" } )

      PermittedParams.new(params, user).cost_type.should == { "name" => "name_test" }
    end

    it "should return unit" do
      params = ActionController::Parameters.new(:cost_type => { "unit" => "unit_test" } )

      PermittedParams.new(params, user).cost_type.should == { "unit" => "unit_test" }
    end

    it "should return unit_plural" do
      params = ActionController::Parameters.new(:cost_type => { "unit_plural" => "unit_plural_test" } )

      PermittedParams.new(params, user).cost_type.should == { "unit_plural" => "unit_plural_test" }
    end

    it "should return default" do
      params = ActionController::Parameters.new(:cost_type => { "default" => 7 } )

      PermittedParams.new(params, user).cost_type.should == { "default" => 7 }
    end

    it "should return new_rate_attributes" do
      params = ActionController::Parameters.new(:cost_type => { "new_rate_attributes" => "new_rate_attributes_test" } )

      PermittedParams.new(params, user).cost_type.should == { "new_rate_attributes" => "new_rate_attributes_test" }
    end

    it "should return existing_rate_attributes" do
      params = ActionController::Parameters.new(:cost_type => { "existing_rate_attributes" => "new_rate_attributes_test" } )

      PermittedParams.new(params, user).cost_type.should == { "existing_rate_attributes" => "new_rate_attributes_test" }
    end

    it "should not return project_id" do
      params = ActionController::Parameters.new(:cost_type => { "project_id" => 42 } )

      PermittedParams.new(params, user).cost_type.should == { }
    end
  end

  describe :labor_budget_item do
    it "should return hours" do
      params = ActionController::Parameters.new(:labor_budget_item => { "hours" => 42.42 } )

      PermittedParams.new(params, user).labor_budget_item.should == { "hours" => 42.42 }
    end

    it "should return comments" do
      params = ActionController::Parameters.new(:labor_budget_item => { "comments" => "comments_test" } )

      PermittedParams.new(params, user).labor_budget_item.should == { "comments" => "comments_test" }
    end

    it "should return budget" do
      params = ActionController::Parameters.new(:labor_budget_item => { "budget" => 42.4242 } )

      PermittedParams.new(params, user).labor_budget_item.should == { "budget" => 42.4242 }
    end

    it "should return user_id" do
      params = ActionController::Parameters.new(:labor_budget_item => { "user_id" => 42 } )

      PermittedParams.new(params, user).labor_budget_item.should == { "user_id" => 42 }
    end

    it "should not return project_id" do
      params = ActionController::Parameters.new(:labor_budget_item => { "project_id" => 42 } )

      PermittedParams.new(params, user).labor_budget_item.should == { }
    end
  end

  describe :material_budget_item do
    it "should return hours" do
      params = ActionController::Parameters.new(:material_budget_item => { "units" => 42.42 } )

      PermittedParams.new(params, user).material_budget_item.should == { "units" => 42.42 }
    end

    it "should return comments" do
      params = ActionController::Parameters.new(:material_budget_item => { "comments" => "comments_test" } )

      PermittedParams.new(params, user).material_budget_item.should == { "comments" => "comments_test" }
    end

    it "should return budget" do
      params = ActionController::Parameters.new(:material_budget_item => { "budget" => 42.4242 } )

      PermittedParams.new(params, user).material_budget_item.should == { "budget" => 42.4242 }
    end

    it "should return cost_type" do
      params = ActionController::Parameters.new(:material_budget_item => { "cost_type" => "cost_type_test" } )

      PermittedParams.new(params, user).material_budget_item.should == { "cost_type" => "cost_type_test" }
    end

    it "should return cost_type_id" do
      params = ActionController::Parameters.new(:material_budget_item => { "cost_type_id" => 42 } )

      PermittedParams.new(params, user).material_budget_item.should == { "cost_type_id" => 42 }
    end

    it "should not return project_id" do
      params = ActionController::Parameters.new(:material_budget_item => { "project_id" => 42 } )

      PermittedParams.new(params, user).material_budget_item.should == { }
    end
  end

  describe :rate do
    it "should return rate" do
      params = ActionController::Parameters.new(:rate => { "rate" => 42.42 } )

      PermittedParams.new(params, user).rate.should == { "rate" => 42.42 }
    end

    it "should return project" do
      params = ActionController::Parameters.new(:rate => { "project" => "project_test" } )

      PermittedParams.new(params, user).rate.should == { "project" => "project_test" }
    end

    it "should return valid_from" do
      params = ActionController::Parameters.new(:rate => { "valid_from" => "2013-05-07" } )

      PermittedParams.new(params, user).rate.should == { "valid_from" => "2013-05-07" }
    end

    it "should not return project_id" do
      params = ActionController::Parameters.new(:rate => { "project_id" => 42 } )

      PermittedParams.new(params, user).rate.should == { }
    end
  end
end
