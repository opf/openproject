require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Meeting do
  it {should belong_to :project}
  it {should validate_presence_of :title}
  
  before(:all) do
    @m = Factory.build :meeting, :title => "dingens"
  end
  describe "to_s" do
    it {@m.to_s.should == "dingens"}
  end
  describe "start_date" do
    it {@m.start_date.should == Date.tomorrow}
  end
end