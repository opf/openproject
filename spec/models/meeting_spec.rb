require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Meeting do
  it {should belong_to :project}
  it {should validate_presence_of :title}
  
  describe :to_s do
    before(:each) do
      @m = Factory.build :meeting, :title => "dingens"
    end
    it {@m.to_s.should == "dingens"}
  end
end