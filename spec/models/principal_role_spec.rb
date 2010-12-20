require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe PrincipalRole do

  describe "ATTRIBUTES" do
    before :each do

    end

    it {should belong_to :principal}
    it {should belong_to :role}
  end

end