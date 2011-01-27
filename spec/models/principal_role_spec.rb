require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe PrincipalRole do

  describe "ATTRIBUTES" do
    before :each do

    end

    it {should belong_to :principal}
    it {should belong_to :role}
  end

  describe :valid? do
    before(:each) do
      @principal_role = Factory.build(:principal_role)
    end

    describe "role not assignable to user" do
      before :each do
        @principal_role.role.stub!(:assignable_to?).and_return(false)
      end

      it { @principal_role.valid?.should be_false }
      it { @principal_role.valid?
           @principal_role.errors.on_base.should eql I18n.t(:error_can_not_be_assigned)}
    end

    describe "role assignable to user" do
      before(:each) do
        @principal_role.role.stub!(:assignable_to?).and_return(true)
      end

      it { @principal_role.valid?.should be_true }
    end
  end
end