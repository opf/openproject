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
  describe "participants" do
    before(:all) do
      @m.participants = [Factory.build(:meeting_participant, :user_id => 1002),
                         Factory.build(:meeting_participant, :user_id => 1003),
                         Factory.build(:meeting_participant, :user_id => 1020),
                         Factory.build(:meeting_participant, :user_id => 12)]
    end
    describe "participant_user_ids" do
      it {@m.participant_user_ids.should == [1002, 1003, 1020, 12]}
    end
  end
end