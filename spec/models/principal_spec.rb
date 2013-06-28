require File.dirname(__FILE__) + '/../spec_helper'

describe Principal do
  describe "ATTRIBUTES" do
    before :each do

    end

    it { should have_many :principal_roles }
    it { should have_many :global_roles }

  end

  describe "WHEN deleting a principal" do
    let(:principal) { FactoryGirl.build(:user) }
    let(:role) { FactoryGirl.build(:global_role) }

    before do
      FactoryGirl.create(:principal_role, :role => role,
                                      :principal => principal)
      principal.destroy
    end

    it { Role.find_by_id(role.id).should == role }
    it { PrincipalRole.find_all_by_principal_id(principal.id).should == [] }
  end
end
