require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  before(:each) do
    @user = Factory.build(:user)
    
    create_non_member_role if costs_plugin_loaded?
  end

  describe "WITH one principal role" do
    before :each do
      @role = GlobalRole.new :name => "global_role"

      principal_role = PrincipalRole.new(:role => @role, :principal => @user)
      principal_roles = [principal_role]
      principal_roles.stub(:find).and_return([principal_role])
      @user.stub(:principal_roles).and_return(principal_roles)
    end

    describe "WITH the role allowing the action" do
      before :each do
        @role.stub!(:allowed_to?).and_return(true)
      end

      describe :allowed_to? do
        it { @user.should be_allowed_to({:action => "action"}, nil, {:global => true}) }
      end
    end
  end
end
