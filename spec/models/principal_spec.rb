require File.dirname(__FILE__) + '/../spec_helper'

describe Principal do
  describe "ATTRIBUTES" do
    before :each do

    end

    it { should have_many :principal_roles }
    it { should have_many :global_roles }

  end

end