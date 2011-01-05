require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  before(:each) do
    @user = User.new
    if costs_plugin_loaded?
      create_non_member_role
    end
  end

  describe "WITH one principal role" do
    before :each do
      @role = GlobalRole.new :name => "global_role"
      #@principal_role = PrincipalRole.new :role => @role, :principal => @user
      @user.principal_roles.build :role => @role
    end

    describe "WITH the role allowing the action" do
      before :each do
        @role.stub!(:allowed_to?).and_return(true)
      end

      describe :allowed_to? do
        before :each do

        end

        it {@user.allowed_to?({:action => "action"}, nil, {:global => true}).should eql @role}
      end


    end


  end
end